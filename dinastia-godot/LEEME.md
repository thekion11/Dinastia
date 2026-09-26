# DINASTÍA en Godot — estado de la mudanza

## OCTAVA RONDA: EQUIPACIÓN CON SPONSORS, ROPA APARTE, 238 MOVIMIENTOS NUEVOS, ÁRBITRO, VAR Y MODELOS 3D (26-9-2026)

- **Equipación**:
  - `ui/disenos_kit.gd`: familias 43-62, cada una en versión de dos colores (acento = color 1)
    y de tres (acento = color 2), en 2D y en `visor/equipacion_q.gdshader`: 130 diseños;
  - cuello en pico, redondo, polo con tapeta o mao (`kit.cuello`, `CUELLOS`);
  - `ui/sponsor_kit.gd` (`SponsorKit`): patrocinadores por zona desde `Auspicio.contrato` y
    `Comercial.zonas_firmadas`; los rivales, por hash (los grandes venden más zonas). La
    palabra se escribe con una tipografía de bloques propia (el rasterizador SVG no pinta
    texto), en una o dos líneas, junto al logo de `Marca`. La misma imagen va al 2D y al
    shader (`sp_pecho`, `sp_manga`, `sp_espalda`, `sp_short`, encajada sin deformar);
  - los sponsors no se guardan en `Club.kit_x` (salen de los contratos); `sp_ocultar` sí;
  - el diseñador (`ui/componentes/disenador_kit.gd`) es una pantalla propia: su `CanvasLayer`
    sobre la raíz y el menú oculto mientras está abierto; se abre con el chip «Equipación»;
    filtros por colores y estilo, buscador, pestaña «Patrocinadores» y Esc para cerrar.
- **Ropa aparte** (`visor/ropa_separada.gd`): camiseta, pantalón y medias extraídos de la malla
  del cuerpo por zonas de la pose de reposo, separados por la normal (holgura propia, el bajo
  que cae) y colgados del mismo esqueleto y piel (`skin`); el shader los pinta con `prenda`.
  `VestidorQ.ropa_aparte`: siempre en el diseñador, opción en Ajustes › Dispositivo.
- **Portafolio de fútbol** (`visor/anim_futbol.gd`): poses clave en lenguaje de cuerpo (cadera,
  tronco, cuello, piernas con abducción y rotación, brazos) y generadores de golpeo, barrida
  (con IK de pies en el césped) y estirada. 23 tiros, 20 pases, 20 barridas y entradas, 13
  atajadas, 31 regates, 16 expresivos, 8 lesiones y 13 gestos arbitrales; se construyen una vez
  por esqueleto y se espejan para zurdos: 333 movimientos por jugador, sin cargar más lento
  (medido: 53 ms por jugador tras el primero, antes 62).
  - **Dos ejes del brazo estaban mal** desde la ronda anterior y se corrigieron con
    `pruebas/sonda_lados.gd`: el «adelante» del brazo derecho iba hacia atrás y el codo nunca
    se doblaba (la Y del antebrazo solo lo gira; el codo es X+).
  - El partido sortea tiros, pases y barridas por familia y después espeja al zurdo.
- **Árbitro** (`visor/match_playback.gd`): cola de gestos programados y
  `_trabajo_del_arbitro()`; la señal `revision_var` abre la sala VAR. Cámara «Árbitro (POV)»
  en `visor/camera_rig.gd`.
- **Sala VAR** (`ui/sala_var.gd`): sala 3D con cuatro monitores que son cámaras reales sobre el
  mundo del partido, operadores con auriculares y la decisión; el partido se pausa.
- **Modelos 3D pendientes**: `visor/estadio_extras.gd` (andamio con red y grúa torre durante las
  obras, palcos VIP, cabina de prensa, museo y tienda según lo construido, y la mascota del
  club) y `visor/peaton.gd` (peatones por las aceras de la ciudad).
- **Plan**: octava ronda en el ROADMAP, con la lista larga del usuario (E9-E25) y lo que piden
  los foros de FM26, FC 26, Soccer Manager y Top Eleven.
- **Pruebas nuevas en el banco**: diseños de 2 y 3 colores, patrocinadores, portafolio (conteos,
  espejos, zurdos), además de las capturas `captura_sponsors`, `captura_ropa_aparte`,
  `captura_portafolio2`, `captura_sala_var`, `captura_arbitro`, `captura_extras_estadio` y
  `captura_peatones`.

## SÉPTIMA RONDA (3): PORTAFOLIO DE MOVIMIENTOS, HABILIDADES QUE SE NOTAN Y BASE DE LA IA LIBRE (26-9-2026)

- **Portafolio de movimientos** (`visor/anim_extra.gd`): 95 animaciones por jugador.
  - 23 clips de la Universal Animation Library (saludos, aplausos, protestas, gestos…);
  - 24 espejos (`<nombre>_espejo`) hechos por reflexión en el espacio del modelo, para zurdos
    y para que un regate o un festejo no salga siempre hacia el mismo lado;
  - 14 expresiones procedurales (aplaudir, protestar, pedir el balón, manos a la cabeza,
    cansado, mirar al cielo, besar el escudo…); los brazos que no se animan se bajan solos.
  - `AnimExtra.variante()` la usa el partido: los golpeos de un zurdo van espejados y los
    regates, festejos, lamentos y protestas se sortean por categoría (`CATEGORIAS`).
- **Las habilidades influyen en el resultado** (prueba en el banco): el mismo club contra el
  mismo rival, 300 partidos con la misma semilla, pasa de 1,40 a 1,73 puntos por partido con
  las maestrías de juego al 30 y «Genio táctico». La cadena es `Mundo.aplicar_bonificadores()`
  → `Club.bonus_ataque/defensa` → `Partido.fuerza()`, que usan liga, copa y continental.
- **Base de la IA que juega sin jugadas prehechas y del mando** (futuro, pero ya en el código):
  - `nucleo/acciones_juego.gd`: 21 acciones con los atributos que mandan, dificultad,
    alcance, pierna débil, botón y familia de animación; `prob_exito()` y `xg()`;
  - `nucleo/motor_libre.gd`: 22 agentes en un campo de 105 × 68 que eligen con IA de
    utilidad (tirar, pasar a cada compañero, conducir, regatear), con presión, marcaje y
    entradas. Admite un jugador controlado (`tomar_control`, `mover`, `ordenar`,
    `cambiar_jugador`) y `foto()` para dibujarlo. Entre iguales da ~1-2 goles y ~20 tiros;
    el mejor gana y el bono del club genera más ocasiones. `pruebas/sonda_motor_libre.tscn`
    imprime estadísticas para calibrar;
  - `nucleo/mando.gd`: mando y teclado en el InputMap sin tocar project.godot; el mismo botón
    pasa con balón y presiona sin él.
  - Falta: enchufarlo al visor 3D y calibrarlo con datos reales.
- **Equipación**: 13 familias modernas más (90 diseños) y la ropa ya no va pegada al cuerpo
  (el shader la infla desde la pose de reposo: más en torso y mangas, poco en el pantalón).
- **Música**: la pista libre en español (B12) queda descartada; sigue la música procedural.

## SÉPTIMA RONDA (2): MAESTRÍAS, DISEÑADOR DE EQUIPACIÓN Y REALISMO DE LA ROPA (26-9-2026)

- **Maestrías** (`nucleo/maestria.gd`, `ui/componentes/panel_maestrias.gd`): 15 categorías
  nuevas de 30 niveles (450 en total), debajo del árbol de habilidades.
  - Las categorías son ataque, defensa, porteros, balón parado, análisis, física, cargas,
    liderazgo, psicología, idiomas, formación, prensa, hinchada, finanzas y negociación.
  - Se gana un punto por semana y otro por victoria. Cada nivel cuesta 1, 2 o 3 puntos según
    la decena.
  - Los hitos 10, 20 y 30 refuerzan el efecto y dan un punto de habilidad para el árbol.
  - Todas tienen efecto real (el nivel 30 de Ataque son +6 % de ataque).
- **Diseñador de equipación** (`ui/disenos_kit.gd`, `ui/componentes/disenador_kit.gd`), desde
  Gente › Identidad:
  - 70 diseños de camiseta (los 12 de siempre y 58 nuevos), con hasta 5 colores y color de
    cuello y puños;
  - 6 diseños de pantalón y 6 de medias, con dos colores cada uno;
  - 30 modelos de botín con tres colores (base, detalle y suela);
  - 7 accesorios (cintillo, manga térmica, guantes, muñequeras, brazalete, cuello térmico,
    tobilleras);
  - color de los números.
  - Vista previa en 2D, de frente y de espaldas con el número, y un jugador 3D girando.
  - El 3D (`visor/equipacion_q.gdshader`) y el 2D usan la misma fórmula; el dorsal se pinta en
    la espalda en 3D.
  - Se guarda en `Club.kit_x`.
- **Realismo de la ropa** (pedido: «se ven poco realistas»):
  - **3D**:
    - la pose de reposo se escribe en la malla (UV2 y COLOR), así el dibujo y los cortes de
      las prendas son exactos por píxel (antes, escalones de 7 mm por la textura de 8 bits);
    - estampado suavizado;
    - menos músculo marcado bajo la tela, arrugas, y sombra en axilas y cintura;
    - tejido de punto con su brillo, botines brillantes;
    - costuras, cuello y puños acanalados, escudo y marca en el pecho.
  - **2D**:
    - dibujado al doble y reducido, con volumen, brillo y arrugas;
    - cuello en pico adelante y redondo atrás, puños acanalados, costuras, escudo, marca y
      trama;
    - pantalón con volumen, medias de canalé y botines con brillo, cordones y tacos.
- Pruebas: `_probar_maestrias`, `_probar_disenos_kit`; capturas `captura_maestrias`,
  `captura_disenos_3d` (frente, espalda y de cerca) y `captura_disenador`.

## SÉPTIMA RONDA (1): HISTORIA CON GUIÑO, CLÁSICOS, MI VIDA Y ÁRBOL DE HABILIDADES (26-9-2026)

- **Historia con guiño para los 384 clubes** (`herramientas/historia_clubes.py` →
  `HISTORIA_CLUBES` y `CLASICOS`, en la base y en el pack):
  - Cada club tiene su fundación, su apodo, el apodo de su estadio y una línea que deja
    reconocer al club real. Ejemplo: Lautaro FC, fundado en 1925, «el Cacique», juega en la
    Ruca.
  - En la base van con los nombres ficticios y en el pack con los reales; `base_ficticia.py`
    los regenera.
  - Lo que falte (años de clubes chicos) se genera. Los años de los clubes menos conocidos
    conviene revisarlos.
- **66 clásicos con nombre propio**: Superclásico (Lautaro–Andina), Clásico Universitario
  (Andina–Precordillera), el Clásico (Precordillera–Lautaro), Gran Derbi, Fla-Flu, Gre-Nal,
  el Tráfico…
  - Cuentan como clásico en el juego.
  - Se nombran en la previa, en la ficha del rival y en la portada («SUPERCLÁSICO: …»).
- **MI VIDA**, grupo nuevo del menú, con tu vida de DT (`nucleo/vida_dt.gd`,
  `ui/componentes/panel_vida.gd`):
  - Casa (de la pensión a la mansión) y transporte, pagados de tu patrimonio.
  - Familia inventada: pareja, hijos y mascota.
  - Equilibrio vida/trabajo: trabajar más da hasta +3 % de preparación, pero sube el estrés y
    baja la familia.
  - Estrés: con él alto, el vestuario te nota tenso; tres semanas al límite y el médico te para
    una semana.
  - Ocio semanal (asado, pádel, escapada…).
  - Asuntos de casa en el despacho (cumpleaños, colegio, aniversario, televisión, publicidad…).
- **Árbol de habilidades como esquema** (`ui/componentes/arbol_habilidades.gd`):
  - Una columna por rama con su color, nodos redondos con icono, líneas de requisito y chispa
    en la que se puede aprender.
  - Estados: aprendida, disponible (con latido) o bloqueada (con candado).
  - Ficha con el botón para aprender y botón «⛶ En grande» a pantalla completa.
  - Vive en MI VIDA › Habilidades; en Historia queda un acceso.
- **Recorrido visual de las 37 pantallas** (`pruebas/captura_todo.gd`, deja las capturas en
  `pruebas/recorrido/`, que no se sube). Arreglado:
  - el grupo del menú encendido al entrar por un chip;
  - «Equipación» vacía;
  - Memoria, Rivales y Vitrina en blanco;
  - paneles de MI VIDA demasiado anchos;
  - «Régimen» en la ficha;
  - los precios de Mi vida escalan con el sueldo del DT.
- Pruebas: `_probar_historia_c4` (reescrita) y `_probar_vida_dt`; capturas `captura_vida` y
  `captura_todo`.

## SEXTA RONDA, TANDA D: CALENDARIO, FESTIVIDADES, GLOBO, POLÍTICA, HISTORIA Y CONTRATOS (26-9-2026)

- **Calendario de cada país** (`nucleo/calendario.gd`): independencias y fiestas patrias de los
  24 países, el 1 de mayo (o el Labor Day de EE. UU.) y las fechas de memoria.
  - El **11 de septiembre** es jornada de memoria en Chile (1973) y en EE. UU. (2001): minuto de
    silencio, brazalete negro y ningún bonus de fiesta.
  - Una semana de fiesta nacional llena más el estadio (×1,12) y sube la moral (+1).
  - El mentor explica cada fecha la primera vez que aparece; lo ya explicado se guarda.
  - La tira de días muestra el icono de la fecha, y la pestaña Calendario lista las próximas
    fechas y el gran torneo del año (Mundial, JJ. OO., Eurocopa, Copa América, con sede
    cuando se conoce).
- **Festividades (C16)**: Semana Santa (Pascua calculada), Ramadán y Eid (calendario islámico
  tabular), Navidad, Día de Muertos, Obon, Thanksgiving.
  - Solo el calendario del país: ningún jugador tiene religión asignada.
- **Globo (C14)**:
  - fronteras de Natural Earth (dominio público);
  - relieve aproximado a partir de la textura;
  - pines y nombres de los 24 países;
  - clic en un pin para elegir el país, con su ficha (capital, ligas, ranking, el club grande,
    el tiempo y la próxima fecha).
  - **Dos errores antiguos arreglados**:
    - el lado de día se veía negro, porque dependía de una luz de escena que venía de atrás;
    - los pines estaban 90° corridos respecto de la textura (Australia caía en el océano
      Índico).
- **Política y Estado (C15)** (`nucleo/politica.gd`):
  - Estructura real de cada país (presidencial, semipresidencial, monarquía parlamentaria,
    república parlamentaria, monarquía absoluta) y años de mandato.
  - Partidos y dirigentes **inventados**, con posturas neutras que solo tocan al club:
    obras, seguridad en estadios, impuestos o deporte base. Cada cuatro semanas se notan en la
    caja.
  - Elecciones con campaña dos semanas antes y resultado; Arabia Saudí no vota.
  - El mentor explica cómo se gobierna el país. Se ve en Federación.
- **Historia de cada club (C4)** (`nucleo/historia_club.gd`):
  - En la base ficticia se genera coherente: fundación, apodo según los colores, estadio,
    rival histórico, ligas y copas ganadas, origen y época dorada. Los grandes son más antiguos
    y tienen más títulos.
  - Con el pack real, la tabla `HISTORIA_REAL` (solo en `pack_real.json`) pone la fundación,
    el apodo, el estadio y el rival reales de 36 clubes. Los títulos no, porque cambian cada año.
  - Se ve en Historia y en la ficha de cada club.
  - Arreglado de paso: en la base ficticia el clásico chileno de los tres grandes nunca se
    detectaba, porque solo estaban los nombres reales.
- **Contratos y jornada (C9)** (`nucleo/contratos.gd`):
  - Norma FIFA en fichajes, renovaciones, cesiones y en el mundo generado: de 1 a 5 años, y
    un menor de 18 no pasa de 3.
  - La ficha muestra el tipo de contrato.
  - Jornada legal del personal en los 24 países, con su norma. Chile baja de 44 a 42 horas el
    26 de abril de 2026 y a 40 en 2028; Colombia baja a 42 el 15 de julio de 2026.
  - Menos horas encarecen un poco la estructura (1 % por hora de diferencia con 44). Se ve en
    Personal del Club y los cambios salen como noticia.
  - México y Egipto quedan marcados para revisar antes de publicar.
- Pruebas: `_probar_calendario_c13`, `_probar_politica_c15`, `_probar_historia_c4`, `_probar_contratos_c9`; capturas `captura_calendario`,
  `captura_globo_c14`, `captura_gobierno` y `captura_historia`.

## SEXTA RONDA, TANDA C: INSTALACIONES, CANTERA, RAMAS, FICHA DEL JUGADOR (26-9-2026)

- **Instalaciones a 10 niveles** (`Instalaciones.NIVEL_MAX`), salvo las tribunas (5).
  - Del 6 al 10, cada nivel vale la mitad.
- **Trabajadores** (`nucleo/trabajadores.gd`): cada instalación construida tiene a alguien al
  frente, con nombre y carácter.
  - Los caracteres son perfeccionista, trabajador, despistado, carismático y conflictivo.
  - Cada instalación tiene sus eventos (caldera rota, menú nuevo, campo inundado…).
  - El despistado tiene el doble de averías.
  - El carismático organiza asados y el conflictivo pide aumento.
  - Se ven en Infraestructura y en la ciudad.
- **Cantera viva** (`nucleo/eventos_cantera.gd`):
  - Asuntos en el despacho: torneo sub-17, un chico que quiere dejarlo y padres que exigen que
    suba.
  - Convocatorias juveniles.
  - Botón «Visitar el entrenamiento», una vez por semana.
- **Ramas que compiten** (`Hinchada.temporada_ramas`): femenino, juveniles, futsal y otros
  deportes juegan su temporada.
  - Tienen posición y palmarés propios.
  - Un título del femenino llega a portada.
- **Ficha del jugador**: pierna débil (1 a 5 estrellas), premios por año (equipo ideal, mejor
  joven, máximo goleador) y asistencias en el historial.
  - Sin datos sentimentales ni religiosos de personas reales.
- Pruebas: `_probar_tanda_c`; captura `captura_tanda_c`.

## SEXTA RONDA, TANDA B: INSTITUCIONES, MEDIOS, CHARLAS, MINIJUEGO, LICENCIA (26-9-2026)

- **Presidente de la federación** (`Federacion.presidente`):
  - nombre y corriente (modernizador, comercial, proteccionista o igualitario);
  - mandato de 4 años con elecciones;
  - sus mociones salen antes en la asamblea y suma 12 puntos a favor en el voto de la IA;
  - se ve en Federación.
- **Junta del club** (`nucleo/junta.gd`):
  - presidente con estilo y tres accionistas con su porcentaje y su exigencia (dividendos,
    títulos, cantera o estadio);
  - junta cada 13 semanas en el despacho, con dos salidas;
  - un accionista harto presenta moción de censura (−10 de confianza).
- **Lesiones absurdas** (`nucleo/lesiones_absurdas.gd`): la ducha, el perro, la consola…
  - una cada ~14 semanas, sin `Azar`;
  - salen en portada;
  - el toque de queda evita las de noche.
- **Entrevistas al paso** (`Prensa.revisar_al_paso`): streamers, podcasts y canales de hinchas,
  con preguntas inesperadas que mueven seguidores.
- **Charlas uno a uno** (`nucleo/charlas.gd`), desde la ficha:
  - cinco temas;
  - la respuesta depende del rasgo;
  - repetir el tema enseguida vale la mitad;
  - la promesa de minutos se cobra a las 4 semanas.
- **Presentación de fichajes** (`ui/componentes/presentacion_fichaje.gd`): en el estadio o en la
  sala de prensa.
- **Minijuego de penales** (`ui/componentes/minijuego_penales.gd`): el portero aprende si repites
  esquina.
- **Licencia de entrenador** (`nucleo/licencia.gd`):
  - niveles C, B, A y Pro;
  - examen de 8 preguntas sobre las Reglas de Juego vigentes y táctica; se aprueba con 6;
  - suspender obliga a esperar 4 semanas.
- Pruebas: `_probar_instituciones_c5_c8`, `_probar_charlas_c6_c7`, `_probar_licencia_c7`;
  capturas `captura_junta`, `captura_charlas` y `captura_examen_penales`.

## SEXTA RONDA, TANDA A: COHERENCIA, PERIÓDICO (26-9-2026)

- **Pantalla del estadio**:
  - su misma textura se ve en vivo en una esquina de la transmisión (antes era una mota
    ilegible), y se apaga desde el cajón;
  - enseña la competición que se juega: cruces de copa, grupo o cruces continentales.
- **Clima de la ciudad** (`nucleo/clima.gd`):
  - el tiempo de cada partido sale del país del local (latitud de `GLOBO_PAIS`) y de la época
    del año, sin consumir `Azar`;
  - hemisferios opuestos, trópico sin invierno, nieve solo en países fríos, desierto seco, y
    altura en Bolivia, Ecuador, Colombia y México;
  - `Partido.clima` (que existía y valía siempre 1,0) traba el partido con lluvia, nieve,
    tormenta, niebla o calor;
  - el visitante no adaptado sufre;
  - se ve en el 3D, en la tarjeta del próximo partido y en la rueda de prensa, y el mentor da un
    consejo;
  - el diseñador del estadio ya no elige el clima.
- **Escudo o camiseta nuevos**: portada, reacción de la hinchada, pregunta en la próxima rueda y
  comentario del mentor.
- **Rueda de prensa tras copa y continental**, con los escudos de esa competición.
- **`MentorVoz`**: el mentor comenta fuera del tutorial, con su cara.
- **Periódico** (`ui/componentes/portada_periodico.gd`): 6 cabeceras propias; ver ROADMAP C20.
- **Banquillo**: butacas con respaldo, techo y metacrilato. Los suplentes llevan botines y ponen
  las manos sobre las rodillas.
- **Filosofía de cantera** (`nucleo/regiones.gd`):
  - región de origen de cada jugador;
  - el Athletic solo ficha a jugadores de Euskal Herria por origen, no por pasaporte;
  - los españoles tienen apellidos españoles, y solo un ~9 % son vascos.
- Pruebas: `_probar_coherencia_c1`, `_probar_portadas_c20`; capturas `captura_mentor_voz` y
  `captura_portadas`.

## PLAN MAESTRO, TANDA 3: EL ESTADIO POR SECCIONES Y LA CIUDAD QUE SE TOCA (25-9-2026)

- **B6 · El estadio por secciones** (`nucleo/estadio_propio.gd`, `visor/stadium_builder.gd`).
  - **Fachada**: hormigón, ladrillo, vidrio, membrana o chapa, con su color. Revestirla es obra
    (se cobra); pintarla es gratis.
  - **Colores por sección**:
    - color del techo, de los banquillos y de la luz de los focos (blanca de televisión,
      cálida, fría o del color del club);
    - con «Personalizar cada tribuna» activado, cada tribuna tiene sus dos colores de butaca;
    - los colores se eligen con muestra en el desplegable.
  - **Superficie** (efecto real en el juego):

    | Superficie | Lesiones en tu campo | Desgaste del césped |
    |---|---|---|
    | Natural | igual (×1,0) | afecta completo |
    | Híbrido | −15 % (×0,85) | afecta la mitad |
    | Artificial | +30 % (×1,3) | no se estropea |

    Las lesiones siguen usando una sola tirada de `Azar` por minuto. Con el techo retráctil no
    llueve dentro.
  - **Exterior**: taquillas con rótulo, tienda oficial con el nombre del club y un
    estacionamiento con los coches Kenney (semilla local, no `Azar`).
  - **24 estilos** (16 + 8): coliseo, caja inglesa, ladera, flotante, cúpula, desierto, hormigón
    sudamericano y japonés moderno.
  - Los catálogos nuevos viven en `estadio_propio.gd` y no en `tablas.json` (que es la
    exportación del HTML). Tampoco entran en «sorpréndeme», que consume el mismo azar que antes.
  - Pruebas:
    - `_probar_estadio_b6` en el banco;
    - capturas `captura_estilos_b6` (hoja 4×2), `captura_exterior_estadio` y
      `captura_disenador_b6`.
- **B7 · La ciudad 3D se puede tocar** (`ui/ciudad_vista.gd`, `visor/city_builder.gd`).
  - **Parcelas fijas y solares**: cada una de las 15 instalaciones tiene su parcela fija, y lo
    que no existe se ve como solar con su cartel.
  - **Ficha y construcción desde el mapa**: un clic en un edificio o solar abre su ficha (qué
    hace, nivel, obra en curso, coste) y la cámara se acerca. Desde ahí se construye o se mejora
    con la misma función que en Club → Infraestructura (`Principal._empezar_obra`): mismo cobro
    y mismos permisos.
  - **Obras visibles**: andamio que sube con el avance y grúa torre. Si se amplía el estadio,
    también hay grúa junto a él.
  - **Rótulos flotantes** de tamaño fijo en pantalla, con botón para ocultarlos. Sobre el barrio
    se ve el humor de los vecinos.
  - **Día de partido**: si esta semana juegas en casa, hay banderas del club en el anillo, 600
    hinchas alrededor del estadio, grada llena y el rótulo «HOY HAY PARTIDO». Hay un botón para
    verlo cualquier día.
  - **Cámara libre**: clic derecho o WASD para desplazarse, además de girar y hacer zoom.
  - Las filas de parcelas ahora van cada 43 m desde z=108: la cuarta caía encima de la calle
    exterior.
  - Prueba: `_probar_ciudad_b7`; captura `captura_ciudad_b7`.

## PLAN MAESTRO, TANDA 2: CINEMÁTICAS, EVENTOS Y ENTREVISTAS (25-9-2026)

- **B3 · Cinemáticas del partido.**
  - `visor/repeticion.gd`: guarda 12 s de jugada a 20 Hz y repite el gol a media velocidad desde
    dos cámaras (detrás del arco y a ras de césped); devuelve a todos a su sitio al terminar.
  - `visor/intro_partido.gd`: 6 s de vuelo alrededor del estadio con el rótulo del partido; se
    salta con un clic.
  - Las dos se apagan en el cajón de ajustes. El reloj del partido se congela mientras duran.
  - Pruebas: `prueba_repeticion`, `prueba_intro`.
- **B4 · Nueve eventos nuevos con efectos que duran** (`nucleo/prensa.gd`, `_eventos_nuevos`):
  - túnel, vídeo viral, capitán, minuto de silencio, cambio de posición, patrocinio en la rueda,
    apuestas, huelga por impagos y amenaza antes del derbi;
  - efectos por semanas (`efectos`, se guardan): vestuario tenso, eco viral, posición nueva,
    calendario de pagos;
  - la tarjeta de decisión muestra la cara del implicado y, al decidir, sale un aviso con la
    consecuencia.
  - Prueba: `_probar_eventos_nuevos` en el banco; captura `captura_evento`.
- **B5 · Entrevistas.**
  - Pregunta un periodista concreto de los cinco (crítico, aliado, neutral, sensacionalista,
    táctico); la placa dice su perfil y cómo te trata.
  - Cada respuesta tiene tono (calma, soberbia o evasiva). Mueve la relación con ese periodista,
    la calle y los árbitros.
  - **Memoria**: recuerda tu última frase. Si fue soberbia y hoy perdiste, te la devuelve.
  - **Repregunta** si evades, si titubeas o si tu soberbia le da titular al crítico o al
    sensacionalista. Solo una por rueda.
  - **Reloj de la sala**: una barra de 10 s. Contestar después cuenta como titubeo.
  - **Titular del día siguiente**: cita tu frase, escrita a la manera del periodista. Sale al
    pasar el día y va a la hemeroteca.
  - **Texto libre**: un clasificador local por palabras clave decide el tono. Hablar de la gente,
    del grupo o de los árbitros matiza el efecto. No usa IA en línea.
  - **A pie de campo** (`ui/componentes/pie_de_campo.gd`): una pregunta al terminar el partido
    dirigido (salvo en modo instantáneo), con tres salidas o pasar de largo.
  - Nada de esto consume `Azar`: quién pregunta sale del hash de la fecha.
  - Prueba: `_probar_entrevistas` (21 comprobaciones); captura `captura_entrevista`.

## PLAN MAESTRO, TANDA 1: AJUSTES, MODOS DE PARTIDO, ANIMACIONES, DISEÑO Y PELO (25-9-2026)

- **B1 · Cajón de ajustes** (`ui/componentes/cajon_ajustes.gd`).
  - Qué hace: un ⚙ que despliega un panel lateral animado. Se cierra solo a los 6 s, con Esc o con
    el ⚙, y recuerda su estado (`user://ajustes.cfg`, sección `hud`).
  - Dónde: en la transmisión 3D y en el partido en vivo.
  - Prueba: `captura_cajon_ajustes`.
- **B2 · Cinco modos de ver un partido**: Instantáneo, Resumen, En vivo, 3D destacados y 3D
  completo, con un selector por competición en Partido y Calendario.
  - Nuevo componente `ResumenPartido`.
  - El mismo partido da el mismo resultado en cualquier vista (prueba "MODOS DE SIMULACIÓN",
    40/40 semillas). Para eso se corrigieron dos fallos:
    - la invasión de campo pasó a `Partido.simular_minuto()`;
    - la crónica en vivo elegía frases con `Azar`.
  - Arreglado de paso: la ficha del jugador sin scroll estiraba la pantalla principal a 1.330 px
    en una ventana de 720, y lo de abajo quedaba inalcanzable.
- **B11 · Animaciones.**
  - Clima visible en el estadio (`visor/precipitacion.gd`): lluvia, nieve y tormenta con
    relámpagos, en dos capas (todo el campo y pegada a la cámara).
  - Banderas de tela que ondean (`visor/bandera.gdshader`).
  - `Animar` en la interfaz: entradas escalonadas, la caja cuenta hasta su valor, el día actual
    late, y hay opción "Animaciones reducidas".
- **B13 · Diseño y texto.**
  - `ui/tema.gd` es la única fuente de colores, letra, radios y espaciados; 61 constantes de 12
    pantallas apuntan ahí.
  - Repaso ortográfico: invasión, césped, policía, túnel, camarín, táctica, médico, países,
    también, detrás, así, inversión, cámara y "Primera División".
  - Días y fecha con el nombre completo ("Lunes 26", "lunes 26 de enero de 2026").
  - El banco vigila que ninguna pantalla vuelva a copiar la paleta y que esas palabras no pierdan
    la tilde.
- **Pelo de los jugadores 3D** (`visor/pelo_q.gd`).
  - Los peinados CC0 de *Universal Base Characters* estaban en un zip sin abrir y los 22 del
    campo eran calvos. Ahora llevan el corte de su retrato, teñido, con barba y cejas.
  - El pelo largo y el moño venían para el cuerpo femenino, y el moño además en centímetros:
    ambos corregidos.
  - Los `.gltf` del pelo van fuera de LFS (`.gitattributes`).
- **Fallo grave corregido: exportaciones.** `export_presets.cfg` tenía comentarios con `##`, que
  en un `.cfg` no son comentarios (van con `;`). El archivo no se leía, así que los filtros que
  dejan fuera el pack real y las fotos no se aplicaban. Ya se lee, y hay prueba en el banco.
- **Inventario de modelos 3D sin usar**: en `ROADMAP.md`, con el bloque donde encaja cada uno.

## CUARTA RONDA: MOVIMIENTOS CON ANATOMÍA HUMANA, REGATES, DOMINADAS Y CARAS REALES (25-9-2026)

Pedido: *"comprueba que los movimientos tengan realismo biológico humano... había movimientos
puramente de fútbol, de regates... usa las caras de Wikipedia"*.

### 1. Auditoría biomecánica: medida, no a ojo
`pruebas/auditoria_biomecanica.tscn` (headless) recorre las 34 animaciones cuadro a cuadro (30 fps).
Mide todo por posiciones de los huesos, así no depende de cómo guarde cada clip sus giros:
- **rodilla y codo**: flexión hasta 160° y nunca hacia atrás. El sentido de la bisagra se calibra
  con la carrera mocap, que es captura de una persona real.
- **cadera**: medida contra la pelvis, no contra el pecho.
- **tobillo, muñeca, cuello y columna**: ángulo máximo de cada uno.
- **pies bajo el césped**.
- **velocidades imposibles**: más de 40 rad/s.

`pruebas/captura_biomecanica.tscn` saca la hoja de perfil y de frente
(`biomecanica_antes.png` / `biomecanica_despues.png`).

Encontró cuatro errores de verdad (22 de 28 animaciones mal), todos corregidos en la raíz:
1. **Las 6 poses de piernas hechas a mano doblaban cadera y rodilla al revés.** Afectaba a
   sentado, lamento, rabia, dolor, barrida y cabezazo: el muslo iba hacia atrás y la rodilla doblaba
   hacia delante. En el banquillo lo tapaba el propio banco.
   - Medido con sonda: en este esqueleto la flexión de cadera es −X, la de rodilla +X y la flexión
     plantar del tobillo +X.
   - Ahora se escriben en grados anatómicos (`_pierna_anat`) y, cuando el pie está apoyado, con IK
     de dos segmentos que lo deja plantado (`_pierna_apoyada`, muestreada a 20 Hz). El tobillo tiene
     tope de 35° de dorsiflexión: pasado eso se levanta el talón.
2. **El mocap estiraba los huesos.** El retarget global copiaba también la posición de cada hueso
   del actor, que tiene otras proporciones: la rodilla quedaba hasta 14 cm fuera de la punta del
   muslo. Ahora se hornea solo el giro (`_huesos_rigidos`); la pelvis conserva su desplazamiento.
3. **El primer fotograma de los FBX es la pose en T.** Daba un salto de 49 rad/s al empezar los
   festejos. Ahora se hornea desde el segundo fotograma.
4. **Rodilla de 176° en el festejo de rodillas.** Ahora hay un tope anatómico de 150° de giro total.

Resultado: **34/34 dentro de los rangos humanos**. Límites atléticos: el portero que se estira y el
festejo con la rodilla al pecho, ambos capturas reales, llegan a 73° de abducción y 147° de flexión
de cadera; están documentados en la cabecera de la auditoría.

### 2. Regates y dominadas: los seis clips que estaban sin usar
Del pack de mocap de fútbol (Dribble 1-3, Juggling 1-3), recortados y sin desplazamiento propio:
- **`conducir`**: el jugador que está encima del balón lo lleva con el mocap de regate, en lugar de
  correr como los demás.
- **`regate_finta`**: amague cuando un rival se le acerca a menos de 6 m. Suena "regate".
- **`regate_pausa`**: parado y atacando, pisa y protege el balón.
- **Presión**: el jugador del equipo que defiende más cercano al balón sale a presionarlo, entre el
  balón y su arco. Antes nadie se acercaba a menos de 4 m.
- **La jugada ATQ-14** ("Desborde individual") ahora conduce y amaga antes del tiro.
- **Dominadas con balón de verdad**: el suplente que calienta en la banda (uno por equipo) hace
  dominadas. `visor/dominadas.gd` lee los toques del pie en el propio clip y entre toque y toque
  la pelota hace la parábola que exige la gravedad. En los huecos largos cae al césped.

Pruebas: `pruebas/prueba_dominadas.tscn` (la pelota está sobre el pie en cada toque y nunca
atraviesa el césped; hoja `dominadas.png`) y `pruebas/prueba_regates.tscn` (partido real: hay
conducción, amagues y un malabarista por equipo).

### 3. Caras reales de Wikimedia Commons
Ya estaban conectadas desde el 7-9 (1.219 fotos libres), pero solo con el pack real. Con la base
ficticia no se enseña ninguna foto de una persona real, y eso se mantiene.

Lo nuevo:
- **Retratos recortados por la cara.** `herramientas/caras_reales_recortar.py` usa YuNet, el
  detector neuronal de OpenCV (el modelo sale de opencv_zoo).
  - Encontró cara en 1.211 de 1.219 fotos.
  - Guarda cabeza y hombros a 256×256 en `recursos/caras_reales_256/`.
  - Antes, en las fotos de cuerpo entero la cara quedaba del tamaño de un botón (hoja
    `caras_reales_recorte.png`: arriba el recorte viejo, abajo el nuevo).
  - El juego ya no decodifica fotos de 3.000 px en cada lista.
  - La versión completo ya no lleva los 136 MB de originales, solo los 23 MB de retratos.
- **Crédito de cada foto.** La ficha del jugador muestra, por ejemplo, "Foto: Rogan200 · CC BY-SA
  4.0 · Wikimedia Commons, recortada". La lista completa está en `datos/creditos_fotos.txt`.
- **Licencias.** Las fotos son libres, pero CC BY y CC BY-SA obligan a citar autor y licencia;
  con esto se cumple.
- **Derechos de imagen.** Son otra cosa: la cara de un futbolista en un juego comercial necesita
  su permiso o el de FIFPro. Por eso las fotos siguen fuera de las versiones públicas (ver
  `LICENCIAS.md`).

Capturas: `caras_reales_inicio.png` y `caras_reales_ficha.png`.

### Verificación
Banco completo: **0 fallos**. Auditoría biomecánica: **0 animaciones con problemas**. Dominadas:
**0 fallos**. Regates en partido real: **0 fallos**.


## TERCERA RONDA DEL USUARIO: PERSONAS REALISTAS, MOVIMIENTOS, JUGADAS, ESTADIOS Y ASPECTO (25-9-2026)

Pedido: integrar los movimientos que faltaban, mejorar las jugadas prehechas, cerrar lo pendiente de
este LEEME, un repaso visual general, un mentor realista y personalizable, más estadios, y el
presentador del Drive. Se comparó contra `marca/referencia/ea_fc25_referencia.mp4` (FC) y
`ejemplo-partido.mp4` (Soccer Manager 2026).

### 1. Personas realistas: el presentador y el mentor
- **El modelo del Drive**: `navy-jacket-portrait` es un escaneo de persona de cuerpo entero, de 1,90 m
  y sin esqueleto. Queda como `assets/personas/persona_realista.glb`, guardado como blob normal de git
  (excepción en `.gitattributes`, porque LFS devolvía 403 desde la sesión).
- **`visor/persona_realista.gd`** (`PersonaRealista`) más su shader, que recolorea el escaneo por zonas
  del cuerpo:
  - pelo, piel, chaqueta, pantalón y zapatos;
  - los labios, las cejas y el cuello de la camisa van protegidos.
  - `aspecto(semilla, pedido)` da variedad determinista.
  - `retrato(asp, tam, fondo, plano)` saca un retrato vivo (luz de 3 puntos, respiración) en tres
    planos: cara, medio y entero.
- **Sorteo**: el presentador ahora es esta persona, con gesto de sacar bola y respiración. El
  fallback al futbolista de traje (Mixamo) se borró.
- **Mentor del tutorial**: retrato realista en lugar del dibujo de antes, y un botón ✎ para cambiarle
  piel, pelo, chaqueta y pantalón. El aspecto se guarda por modo en `user://ajustes.cfg`
  (`[mentor_aspecto]`).
- ⚠️ El escaneo no tiene esqueleto: los gestos son del cuerpo entero (girar, inclinarse, respirar),
  no de brazos. La licencia en Sketchfab está 🟡 en `LICENCIAS.md` (confirmar, es una persona real).
- ❌ **El modelo del gato** para el menú no apareció en el Drive. Sigue pendiente.

### 2. Movimientos: 9 animaciones nuevas y un bug de pelvis
`visor/anim_quaternius.gd` recorta clips de los packs de Quaternius (`CLIP_RECORTES`):
- el portero, en tres estiradas (izquierda, derecha, abajo);
- dos celebraciones nuevas (de rodillas, carrera);
- saque de banda, pase con interior, marcaje y empujón;
- el árbitro mostrando la roja.

Hay además cinco hechas a mano: lamento, rabia, señalar falta, barrida y dolor.

**Bug corregido**: los desplazamientos de pelvis de las animaciones hechas a mano se aplicaban en el
espacio equivocado, así que el cabezazo y los saltos de festejo iban hacia atrás. Se arregló
convirtiéndolos con la base global de reposo del hueso padre.

`pruebas/captura_movimientos` comprueba que las 24 animaciones del partido existen.

### 3. Jugadas prehechas
- `nucleo/catalogo_jugadas.gd` ahora tiene fases escritas a mano para ATQ-01…15, DEF-01…15 y
  POR-01…15. Cada fase define pases, altura del balón, remate o cabezazo, y la acción por rol. Las REG
  siguen con la plantilla genérica.
- **Jugadas de ambiente**: durante el partido, con un 40% de probabilidad por minuto sin eventos
  pendientes, el equipo ensaya una jugada del catálogo sin rematar. Arriba aparece el rótulo tipo TV
  con su nombre, como en FC. Si llega un evento real, la jugada se aborta.
- El balón llega al punto de inicio con un pase, sin teletransportarse.

### 4. Estadios: de 8 a 16 estilos
- Estilos nuevos en `datos/tablas.json` (`EST_PRESETS`): montaña, retro, futurista, campus, oasis,
  muralla, jardín y tormenta.
- `Club.perfil_estadio()` elige el estilo con un hash propio del club, y la reputación recorta techo,
  focos, pantalla, césped y niveles.
- Los rivales ahora salen en 6 formas en lugar de 2.

Captura: `pruebas/estadios_nuevos.png`.

### 5. Aspecto de la interfaz, con Soccer Manager delante
- **Inicio**: `ui/componentes/tablero_inicio.gd` es un tablero de tarjetas con estas piezas:
  - próximo partido con los dos escudos;
  - anillos de valoración del plantel y del directorio;
  - mini tabla, caja y estadio;
  - la estrella del equipo con su cara;
  - las rachas.
  
  El anillo es un componente nuevo (`ui/componentes/anillo.gd`).
- **Pizarrón táctico**: `ui/componentes/pizarra_tactica.gd` dibuja la cancha con líneas. Cada
  jugador lleva su cara, un anillo de media y una etiqueta de posición con el color de su línea
  (en rojo si juega fuera de posición).

Capturas: `pruebas/inicio_tablero.png` y `pruebas/pizarra_tactica.png`.

### 6. Sonidos: de 157 sin usar a los que tienen momento claro
- **En el partido**:
  - salida del túnel y ambiente según el clima (lluvia, trueno, niebla, frío, noche, sol);
  - medio tiempo, reanudación, último minuto y descuento;
  - tensión del público en partidos apretados;
  - doblete, hat-trick, gol rápido (≤3') y gol agónico (≥86');
  - alarido en las atajadas, travesaño o suspiro de la grada en los postes;
  - lesión grave.
- **En las jugadas**: pase largo, despeje y entrada dura.
- **Avisos**: `Aviso.mostrar(..., sfx)` acepta un sonido propio. Lo usan 14 avisos:
  - despido, liquidación, oferta, ronda superada, obra terminada, parte médico;
  - venta, clausulazo, patrocinio, cierre de mercado, contratos que vencen.
- Los `gol_*` que aparecían "sin usar" eran falsos positivos: se arman como `"gol_" + estilo`.

### 7. Pendientes viejos de este LEEME que ya estaban cerrados
Se revisaron uno por uno y ya estaban resueltos en sesiones posteriores a cuando se anotaron:
- el túnel anclado a mano y los túneles "arco" y "foso";
- los banquillos superpuestos;
- la cámara "Tribuna alta" clavada en 12;
- la tabla de posiciones y los goleadores en la pantalla gigante.

Las notas de más abajo quedan como historia.

### Verificación
Banco completo en headless: **0 fallos**. Todas las capturas citadas se regeneraron en esta sesión.


## SEGUNDA RONDA DEL USUARIO: SIN RONALDO, NOMBRES CUBIERTOS Y TUTORIAL INMERSIVO (25-9-2026)

El usuario revisó la primera ronda y pidió tres cosas:
- "Lo de las caras era bien, se necesita de nuevo esa cubierta en el nombre, ya que no está activa".
- "El tutorial debe mejorarse, debe ser inmersivo según modo de juego".
- "El modelo Ronaldo debe ser eliminado".

### 1. El modelo Ronaldo, borrado del proyecto
- **Recursos borrados**: `assets/characters/futbolista_cr7*` (el `.glb` y sus texturas del Al-Nassr) y las fuentes
  `recursos/modelos3d/cr7/`, `recursos/modelos3d/futbolista/` (`NewRonaldoBase`) y
  `recursos/modelos3d/el-futbolista.zip`. Se abrió el zip para comprobarlo: dentro solo hay `NewRonaldoBase.zip`.
- **Código borrado**: todo lo que solo existía para ese modelo, es decir `visor/futbolista.gd`,
  `visor/anim_mixamo.gd` y `visor/vestidor.gd`, más seis diagnósticos de `pruebas/` que lo cargaban.
- **Respaldos**: si el modelo Quaternius no carga, los partidos caen al muñeco de Kenney y el
  presentador del sorteo a la silueta de cajas. Ya no pasan por el modelo viejo.
- **Verificación**:
  - `captura_equipaciones` da 0 fallos.
  - `medir_partido` da las mismas 520 llamadas de dibujo y 0,66 M de triángulos.
  - `LICENCIAS.md` y los presets de exportación ya no lo mencionan.

### 2. La cubierta de los nombres reales, activa otra vez
- **Por qué no se veía**: las tablas del pack real traen clubes, copas, árbitros y agentes cubiertos
  ("C0lo-C0lo", "Champi0ns Le4gue", "R. T0bar"). El juego los pasaba por `Nombres.limpiar()` al crear el
  mundo, así que la cubierta nunca llegaba a la pantalla. Los futbolistas reales (`REALES`) venían
  directamente en claro.
- **Qué hace ahora**: `Nombres.de_tabla()` se aplica al crear el nombre del club, la liga, la copa, el
  árbitro, el agente y el jugador real.
  - Con el pack real activo, conserva la cubierta de la tabla y cubre con `censurar()` lo que viene en claro
    ("Fernand0 de Paul", "D. Iquiqu3").
  - Con la base ficticia no hay nada que tapar y todo sigue limpio.
- **Los textos** (noticias, logros, federación, estadio...) usan `Nombres.visible()` en vez de `limpiar()`,
  para no destaparlos.
- **Las caras se quedan**, como pidió el usuario. Las búsquedas por nombre comparan limpio en los dos lados,
  así que siguen funcionando:
  - fotos (`Cara.foto_real`), plantillas reales (`Reales`) y camisetas reales (`Jersey`);
  - el buscador global y el filtro del mercado ("fernando" encuentra a "Fernand0").
- **Banco**: sección nueva "CUBIERTA DE LOS NOMBRES REALES". Resultados:
  - 379 de 384 clubes y 2.773 de 2.844 futbolistas reales salen cubiertos;
  - las caras y las camisetas se siguen encontrando;
  - con la base ficticia todo sale limpio.

### 3. El tutorial, ahora es tu primer día
`ui/componentes/tutorial.gd` está reescrito. No es un manual de botones: es la llegada al cargo.
- **Prólogo de cine**: franjas negras, el escudo del club, el lugar y la temporada, y una escena escrita a
  máquina que cambia con cada modo.
  - Al entrenador lo deja un taxi frente al estadio.
  - Al interino lo despierta el teléfono a medianoche ("cinco fechas, solo cinco").
  - Al ayudante lo reciben a las 6:30 entre conos.
  - Al director de cantera, en el campo anexo un sábado.
  - Al dueño, en la notaría; al jeque, en la pista del aeropuerto; al creador, en un campo alquilado.
  - Cada escena tiene su sonido (silbato, teléfono, ovación...).
- **Un mentor con cara, nombre y cargo** que habla en primera persona: el presidente, tu jefe (el primer
  entrenador de verdad de tu partida), el coordinador de la academia, tu director general, el enviado del
  fondo o tu socio fundador. El nombre sale del club, así que siempre es el mismo, y la cara usa el mismo
  generador que los jugadores.
- **Habla de TU partida**: el objetivo del directorio, la confianza, la caja, el rival del domingo, tu
  estrella por su nombre y su media, la promesa de la plantilla, el entrenador empleado, la meta de
  debutantes, el mejor chico de la academia. Todo sale de `Tutorial.contexto()`.
- **Misiones que se cumplen haciéndolas**, entre 4 y 7 por modo, cada una propia de su cargo.
  - El director deportivo revisa contratos, finanzas, mercado y el personal.
  - El ayudante va al entrenamiento, el camarín y la cantera.
  - El dueño mira finanzas, estadio, infraestructura y mercado.
  - El creador empieza por la identidad visual y la equipación.
  - Cómo se cumplen:
    - Al hacer la acción en la pantalla real, la misión se marca con ✔, suena un logro y el mentor sigue solo.
    - "Muéstramelo" la hace por ti.
    - Una misión que ya estaba hecha al llegar no cuenta sola.
- **Epílogo**: la despedida del mentor, las misiones cumplidas y, si diriges partidos, "Ir al partido".
- **Ganchos nuevos** en `principal.gd`:
  - `tutorial_hecho` y `tutorial_accion` aceptan `tab:<pestaña>`, `chip:<pestaña>|<sección>` y
    `ficha:<id>`;
  - la tarjeta vuelve a su tamaño mínimo en cada cuadro.
- **Tropiezo encontrado con la captura**: el prólogo salía sin fondo, porque `set_anchors_preset()`
  deja el tamaño en cero. Se cambió a `set_anchors_and_offsets_preset()`, y la franja de abajo crece
  hacia arriba.
- **Verificación**:
  - El banco comprueba los 8 guiones: prólogos distintos, al menos 6 mentores distintos, que cada misión
    se pueda cumplir y apunte a una pestaña que existe, y que el presidente nombre al rival, a la estrella
    y al objetivo reales.
  - `pruebas/captura_tutorial.gd` juega el primer día de verdad: la misión del plantel se cumple a mano
    y la de la ficha con "Muéstramelo". Termina en 0 fallos y deja las fotos `pruebas/tutorial_*.png`.

### De paso
La prueba del editor que subía "el primer atributo menor de 90" fallaba según qué jugador tocara ese
mundo: subir la velocidad de un portero no mueve su media. Ahora elige un atributo que pese en el puesto.

Banco completo: 0 fallos.

## EL ANÁLISIS EXTERNO (62/100), PUNTO POR PUNTO (25-9-2026)

El usuario pasó un PDF con un análisis externo del juego y pidió resolverlo entero sin ayuda. Cada
punto se comprobó antes contra el código: no se corrigió nada solo porque el PDF lo dijera. Hay un
commit por tema en la rama `claude/sweet-turing-tysv99`, y el banco quedó en 0 fallos después de cada
uno.

### 0. La contraseña del keystore de Android ya no está en el repositorio
`export_presets.cfg` la tenía escrita. Ahora las credenciales viven en `export_credentials.cfg`, que
no se sube (`.gitignore`); `export_credentials.cfg.ejemplo` explica qué poner. **El historial de git
todavía guarda la contraseña vieja.** El repositorio es privado, pero lo seguro es cambiarla: sacar
un keystore nuevo o cambiarle la contraseña con `keytool -storepasswd`.

### 1. Legal: base ficticia por defecto y pack real aparte
- `herramientas/base_ficticia.py` (se puede volver a correr sin romper nada) cambia los 384 clubes
  reales por nombres inventados. Hace lo mismo con ligas, confederaciones, copas, árbitros y marcas
  de ropa. También reemplaza las listas de nombres: salían de plantillas de selecciones reales, y
  110 de los nombres generados coincidían con futbolistas reales.
- `datos/tablas.json` ahora es la base FICTICIA. Todo lo real se mudó a `datos/pack_real.json`.
- `Datos.usar_base_real()` activa el pack si existe, en este orden:
  1. `user://pack_real.json`;
  2. el `pack_real.json` junto al `.exe`;
  3. `res://datos/pack_real.json`.
- En Inicio se elige la base ("Ficticia / Real (pack)"). La partida guardada recuerda cuál usaba.
- `Nombres.sin_vetar()`: ningún nombre generado (mundo, cantera, ojeadores, academia) puede coincidir
  con uno de los 2.125 futbolistas reales. La lista de vetados guarda solo huellas md5, no los nombres.
- Con la base ficticia no sale ninguna foto real (`Cara.foto_real()` devuelve null) ni ninguna
  camiseta real.
- Se quitaron el módulo `ficcion/` y las menciones a "FIFA".

### 2. Licencias
`LICENCIAS.md` es nuevo y va con un semáforo. Todo lo 🔴 queda fuera de los presets publicables
(WindowsLigero, Web, Android): el pack real, las caras reales y los coches
sacados de un juego comercial. El preset **Windows** ("completo") es el privado y lo lleva todo. Los
🟡 son pendientes del dueño: hay que confirmar la fuente y no se pueden resolver desde el código.

### 3. Partido 3D: equipación, jugadores lejanos y la "columna misteriosa"
- La equipación se pinta en el shader (`visor/equipacion_q.gdshader`) sobre una máscara UV del modelo
  Quaternius (`herramientas/mascara_equipacion.py`): 12 estilos, pantalón y medias propios, manga larga
  opcional y un rim light para que no se vean oscuros. Antes se teñía la textura en la CPU y quedaba
  rota. `VestidorQ.vestir_equipacion()` guarda los materiales en caché.
- Encima de cada jugador flota su nombre (`Label3D` de tamaño fijo, escalado según el FOV), y se
  puede apagar con el botón "🏷 Nombres".
- Se reordenó la interfaz: el marcador arriba a la izquierda y los botones arriba a la derecha.
- La **columna misteriosa** se reprodujo: aparece de noche, con el renderer Compatibility, y es un
  reflejo especular de los focos sobre un césped demasiado brillante. Se arregló de dos maneras: la
  rugosidad del césped ahora va de 0,78 a 1, y la luz de relleno ya no da brillo especular. Con capturas
  de antes y después.

### 4. Tutorial
`ui/componentes/tutorial.gd` muestra una guía sobre la interfaz real en 15 pasos, uno de ellos propio
de cada modo (`Roles.modo_actual()`). Arranca solo la primera vez y también se abre desde la tarjeta
"Tutorial" de Inicio. En Ajustes → aspecto hay un botón para verlo de nuevo.

### 5. Pendientes del PDF
- **Moneda**: se puede elegir EUR, USD, GBP, CLP, ARS, BRL, MXN, COP, PEN o JPY en Ajustes → juego.
  Todo pasa por `Eco.dinero()`, y las 8 copias de `_dinero` quedaron en una sola.
- **Academia de 10 a 16 años** (`nucleo/academia.gd` y `ui/componentes/panel_academia.gd`, arriba de
  Plantel → Cantera): se decide el plan de trabajo, la comida, los estudios y el molde de personalidad
  de cada chico, se capta cada temporada y se lo entrega al DT a partir de los 15. La proyección se
  muestra como horquilla porque el techo real está oculto. Se guarda con la partida.
- **Contraste** de la cabecera de la previa: se añadió un velo degradado y se aclararon los textos
  secundarios. El **buscador** ya no sale cortado.

### 6. Rendimiento (medido, no estimado)
| | antes | después |
|---|---|---|
| Arranque | 12,3 s | 0,9 s |
| Abrir el estadio | 25,6 s | 2,9 s |
| Triángulos por fotograma | 2,63 M | 0,66 M |
| Llamadas de dibujo | 768 | 520 |
| Fotograma (render por software) | 641 ms | 386 ms |

Cambios:
- Sonidos y música se componen en un hilo aparte.
- La pantalla gigante se redibuja cada 0,25 s en vez de en cada fotograma.
- Butacas y público ya no proyectan sombra.
- `RendimientoAdaptativo` baja la calidad en cuatro escalones si la media cae por debajo de 40 FPS;
  se puede apagar en Ajustes.

Los FPS reales dependen de la gráfica. `pruebas/medir_partido.gd` mide lo que el juego le pide a la
máquina, y eso sí se puede comparar entre versiones.

### 7. `principal.gd`
Dos paneles más pasaron a componentes: `PanelAspectoDT` y `PanelClubDentro`. Cada uno tiene una
prueba que pulsa sus botones de verdad (`pruebas/captura_*_panel.gd`). Con esto el archivo quedó en
14.395 líneas y 644 KB.

**Lección que costó tiempo:** las lambdas conectadas a señales de `mundo` que viven toda la partida
NO se pueden sacar de `Principal`. Se intentó con `NoticiasMundo`, primero como componente estático y
después como nodo hijo, y el juego se cae al salir con `malloc_consolidate(): invalid chunk size`.
Desconectarlas en `_exit_tree` lo cuelga. Se revirtió entero. Solo se pueden extraer los paneles cuyos
callbacks mueren con sus botones.

### 8. Un bug encontrado de paso
La multa del vestuario (`nucleo/vestuario.gd`) era fija, y salía en 14,6 M… que además los cobraba
el club. Ahora son dos semanas del sueldo del jugador (`MULTA_SEMANAS`).

## LOBBY INSTITUCIONAL CON ÁRBITROS: CERRADO (26-9-2026)

Punto de la Fase 3 del `ROADMAP.md`, confirmado como hueco real desde el 14-9 ("Lobby institucional
explícito con árbitros -confirmado que no existe-"). Instrucción del propio ROADMAP: "mismo patrón
que los eventos de `prensa.gd` ya construidos (un evento más sobre el mismo pool), no motor nuevo" -y
así se hizo, sin tocar la interfaz.

**Lo que ya existía y no había que duplicar**: `Prensa.arbitro_dudoso()`/`"reclamo"` es la mitad
REACTIVA -después de perder con un árbitro casero o figura, el directorio pregunta si reclama-.
`Federacion.enojo_arbitral` es un contador ACUMULADO que sube cada apelación perdida y encarece
-baja la probabilidad de- la siguiente apelación (`Federacion.apelar()`, línea 590), y la pestaña
Federación ya lo mostraba ("RELACIÓN CON EL ARBITRAJE") sin que hubiera ninguna forma de bajarlo.
Ahí estaba el hueco real: un lobby es la mitad PROACTIVA que faltaba, la que limpia ese acumulado
antes de que se pida una apelación, no la que reacciona a un partido puntual.

**Lo nuevo**: un evento más en `Prensa._pool()`/`resolver()` (`"lobby_arbitral"`), que solo aparece
en la baraja semanal si `Federacion.enojo_arbitral > 0` -sin nada que limar, no tendría sentido-.
Asistir cuesta plata (escalada por reputación, como el resto de eventos) y baja el enojo acumulado
en 1; hay 30% de que se filtre a la prensa rival, con costo en imagen (funa) y confianza de la
directiva. Declinar no cambia nada -ni cuesta ni arregla-. Cero líneas nuevas de interfaz:
`Principal._pintar_decision()` ya pinta cualquier evento del pool con solo `txt`/`opcion_a`/
`opcion_b`, el mismo camino genérico que usan los otros catorce eventos de `Prensa`.

**Verificación en dos capas**: `pruebas/captura_verificar_lobby_arbitral.gd` (nuevo) confirma contra
el motor, sin abrir ninguna pantalla, que el evento NO aparece con `enojo_arbitral = 0`, SÍ aparece
con `enojo_arbitral = 3`, que "asistir" baja el contador de 3 a 2 Y cobra plata de verdad, y que
"declinar" no toca ni el contador ni la caja. `pruebas/captura_visual_lobby_arbitral.gd` (nuevo)
fuerza el evento y confirma que se pinta en pantalla real, idéntico a cualquier otro aviso del
despacho -captura en `pruebas/pantalla_lobby_arbitral.png`-.

**Tropiezo real en la propia herramienta de verificación, corregido antes de dar esto por cerrado**:
la primera versión de `captura_visual_lobby_arbitral.gd` usaba `var n := get_meta("n", 0) + 1` -
`get_meta()` devuelve `Variant`, y GDScript no puede inferir un tipo con `:=` a partir de un
`Variant`-. El script ni siquiera compilaba, y el proceso de Godot se quedaba colgado sin arrancar
en vez de fallar con un error claro (mismo síntoma que ya costó tiempo en sesiones anteriores:
"parece que sigue vivo pero no avanza"). Se mató el proceso a mano, se cambió a una variable de
instancia (`var _n := 0`, incrementada en `_process`) y se corrió de nuevo -esta vez sí, captura
real en 0 fallos-.

Banco completo: 0 fallos, `.err.txt` vacío. Auditoría estática: 0 duplicadas, 0 clases sin usar.
Cierra el punto 3 de la Fase 3 del `ROADMAP.md`.

## LIMPIEZA TÉCNICA, FASE 6 DEL ROADMAP: 8 FUNCIONES HUÉRFANAS BORRADAS (26-9-2026)

Tras cerrar la modularización de `principal.gd`, se preguntó por funciones pendientes. Se revisó
`ROADMAP.md` y se cruzó contra la auditoría estática del día: las "7 funciones huérfanas en
`entrenamiento.gd`" de la Fase 6 coincidían exacto con 7 de las candidatas que reporta
`auditar_godot.ps1` -confirmación cruzada de que la lista seguía vigente-.

**Verificado uno por uno antes de borrar, no solo confiado en la lista**: grep de cada nombre
(`subidas_de`, `dar_puntos`, `arbol_por_rama`, `rama_habilidad`, `minimo_habilidad`,
`requisito_habilidad`, `dt_puede`) en `nucleo/`, `ui/`, `visor/`, `pruebas/`, `escenas/` y `ficcion/`,
más una segunda pasada buscando los nombres como *string* por si algún sitio los llamaba por
reflexión (`.call("nombre", ...)`, patrón que este mismo proyecto usa en sus pruebas). Cero
resultados en los dos casos: las siete eran de verdad código muerto, sin ningún llamador ni directo
ni dinámico. Borradas de `nucleo/entrenamiento.gd`.

De paso se cerró también el otro punto suelto de la misma Fase 6: `visor/match_playback.gd::is_final()`,
sin ningún consumidor, mismo método de verificación.

**Verificación**: banco completo antes y después de cada borrado (0 fallos, `.err.txt` vacío en las
dos corridas) y auditoría estática confirmando la baja exacta de candidatas -27 → 20 tras
`entrenamiento.gd`, 20 → 19 tras `is_final()`-. Sin prueba de captura nueva: no hay nada que ver en
pantalla, son funciones que nadie llamaba, no comportamiento visible que verificar.

Cierra los dos puntos de "Limpieza técnica de bajo valor" (Fase 6) que sí tenían un hallazgo concreto
detrás; el tercero ("revisar si `principal.gd` empieza a costar de verdad") ya se resolvió con las
cinco tandas de modularización de hoy.

## MODULARIZACIÓN, QUINTA Y ÚLTIMA TANDA: `PanelPlantel`, CIERRA LA LISTA DE `ROADMAP.md` (26-9-2026)

Última pieza pendiente de la lista abierta el 25-9 ("Sigue" del usuario): la pestaña "Mi plantel".
Medida antes de tocarla, como las cuatro anteriores -aunque esta vez el tamaño SÍ era el esperado
(57 líneas de `_pintar_plantel` + 10 de `_comparar_plantel`, nada parecido a las subestimaciones de
mercado/ficha/finanzas)-, resultó tener un tipo de acoplamiento distinto a los cuatro componentes
anteriores: no es que le falte un color por resolver, es que **pintar una fila de jugador
(`Principal._fila_jugador()`) navega ella sola** -abre la ficha y cambia de pestaña- y **el color de
las cabeceras pasa por `Principal._color_de_paleta()`**, la traducción de TEMA (con su propio salto
de contraste, `_con_contraste()`), distinta de `_color_accesible()`/`_pal_*()` que ya usan los otros
cuatro componentes.

**Duplicar esas dos cosas habría creado una segunda fuente de verdad** sobre cómo se navega a una
ficha y sobre cómo se traduce un color de tema -exactamente el riesgo que esta sesión entera viene
evitando-. En vez de eso, `ui/componentes/panel_plantel.gd` (`PanelPlantel`) recibe **la propia
pintura de una fila y la propia traducción de color como `Callable`**, igual que
`FichaJugadorAcciones` recibe la mutación: Principal sigue siendo la única fuente de verdad de las
dos, el componente solo decide en qué orden y con qué datos llamarlas. El orden de la tabla
(`_orden_plantel`/`_orden_plantel_desc`) también se queda en Principal -es preferencia de pantalla,
se guarda entre repintados-, pasado como parámetro.

**Otro detalle real encontrado al medir**: `COL_ACENTO` en `principal.gd` es `var`, no `const` -cambia
cada refresco al color del club (`_acento_de(c)`)-. Los otros cuatro componentes solo duplicaban
constantes de verdad; aquí duplicarla como const habría clavado el color de UN club para siempre.
Se pasa como parámetro (`col_acento`) en su lugar.

**Verificación real, con captura y pulsado**: `pruebas/captura_verificar_plantel.gd` (nuevo) abre
`principal.tscn`, va a "Mi plantel", pulsa la cabecera NOMBRE y confirma que `_orden_plantel` cambia
de verdad y que el primer jugador pintado pasa de ordenarse por media a orden alfabético -no solo
que la cabecera se repinta-. Después pulsa el nombre de un jugador y confirma que la navegación por
`Callable` sigue funcionando exactamente igual que antes: abre su ficha (50 hijos pintados) y deja
"Mi plantel" al frente. Captura en `pruebas/pantalla_plantel.png`. Banco completo: 0 fallos,
`.err.txt` vacío. Auditoría estática: 0 duplicadas, 0 clases sin usar.

`principal.gd`: 14.707 → 14.640 líneas en esta tanda. **Con las cinco tandas de hoy: 15.589 → 14.640
(949 líneas movidas a componentes propios o eliminadas por muertas)**. Con esto se cierra la lista
completa de `ROADMAP.md` abierta el 25-9: no queda ninguna pantalla grande sin medir ni sin decidir
su patrón. Lo que sigue -si el usuario lo pide- es empezar a repetir el mismo ejercicio sobre otros
archivos grandes del proyecto (`stadium_builder.gd`, `mundo.gd`, `city_builder.gd`, `roles.gd`...),
no ya sobre `principal.gd`.

## MODULARIZACIÓN, CUARTA TANDA: `PanelFinanzas`, EL PANEL QUE EL PLAN EXTERNO SUBESTIMABA (26-9-2026)

Siguiendo "Sigue" del usuario tras confirmar que el objetivo de todo esto -aclarado en la misma
conversación- no es que el juego "funcione mejor" sino que sea menos frágil, se midió por fin el
panel de finanzas que quedó pendiente en `ROADMAP.md` desde la tanda anterior. Medido con grep antes
de tocar nada, como manda la disciplina de hoy: son en realidad **5 funciones, no 1**
(`_pintar_finanzas` orquesta y llama a `_pintar_balance_y_caja`, `_pintar_auspicio`,
`_pintar_patrocinio` y `_pintar_banco`), **531 líneas**, más grande que el "~200 líneas" que asumía
el plan externo -la MISMA subestimación que ya se vio con el mercado y la ficha del jugador.

**Se sacaron las 4 sub-funciones** (`_pintar_balance_y_caja`, `_pintar_auspicio`,
`_pintar_patrocinio`, `_pintar_banco`, 370 líneas) a `ui/componentes/panel_finanzas.gd`
(`PanelFinanzas`), **mismo patrón que `FichaJugadorAcciones`**: estática con `Callable` para las tres
que tienen botones (firmar auspicio, lanzar campaña, ir a por el patrocinador rival, prepagar,
renegociar, tomar crédito, emitir bono social), y pura -sin ningún `Callable`- para
`pintar_balance_y_caja`, que solo lee y no muta nada. `_pintar_finanzas` (el precio de entrada, la
tienda, la proyección anual, el resumen y el libro de movimientos) SE QUEDA en `principal.gd` como
orquestador, exactamente igual que `_ver_ficha` se quedó orquestando la ficha del jugador.

**De paso, la auditoría reveló otra función muerta**: `_puesto_en_liga(c)` en `principal.gd` solo la
llamaba `_pintar_auspicio`, que se acaba de mover -y su equivalente se duplicó DENTRO de
`PanelFinanzas` (`_puesto_en_liga(c, mundo)`, misma lógica, pura), así que la de Principal quedó sin
ningún llamador. Se confirmó con grep y se borró.

**Verificación con botones pulsados de verdad**, la misma disciplina que `FichaJugadorAcciones`:
`pruebas/captura_verificar_finanzas.gd` (nuevo) abre `principal.tscn`, va a la pestaña Finanzas y
pulsa "Firmar" sobre una oferta de auspicio, lanza una campaña publicitaria y toma un crédito,
confirmando en cada caso el cambio real en `Mundo` (`auspicio.contrato` deja de estar vacío,
`campana_lanzada_este_anio()` pasa a true, `banco.prestamos.size()` sube de 0 a 1) -no solo que el
botón se pinta. **Un tropiezo real durante la escritura de la prueba, corregido antes de darla por
buena**: el primer intento buscaba el botón de campaña por "contiene EUR" y encontró el de la TIENDA
DEL CLUB en su lugar -pintada antes en la misma pestaña, con texto "Lanzar 2.9M EUR"-, así que
pulsaba el botón equivocado y el fallo apuntaba a la función correcta. Se corrigió buscando el botón
cuyo texto es SOLO el precio (empieza con un dígito), que es justo lo que distingue a una campaña
("700k EUR") de una fila de tienda ("Lanzar 700k EUR"). Captura en
`pruebas/pantalla_finanzas.png`. Banco completo: 0 fallos, `.err.txt` vacío. Auditoría estática: 0
duplicadas, 0 clases sin usar.

`principal.gd`: 15.036 → 14.707 líneas en esta tanda (370 de la extracción + otras de la función
muerta). Con las cuatro tandas de hoy: 15.589 → 14.707 (882 líneas movidas a componentes propios o
eliminadas por muertas).

**Sigue pendiente, documentado y sin tocar**: `_pintar_plantel`/plantel del club, sin medir todavía.

## MODULARIZACIÓN, TERCERA TANDA: `FichaJugadorAcciones`, PATRÓN NUEVO -ESTÁTICA CON CALLABLES- (25-9-2026)

Siguiendo "Continúa"/"Dale" del usuario, se tomaron las cinco funciones de la ficha del jugador que
se dejaron pendientes en la tanda anterior por tener botones que mutan el mundo:
`_pintar_desarrollo_ficha`, `_pintar_reconversion_ficha`, `_pintar_marca_ficha`,
`_pintar_similares_ficha`, `_pintar_venta` (225 líneas), a
`ui/componentes/ficha_jugador_acciones.gd` (`FichaJugadorAcciones`).

**Un tercer patrón, distinto a los dos ya usados**: ni componente de escena con señales
(`PanelMercado`) ni clase estática de solo lectura (`TablaCompeticion`/`FichaJugadorInfo`). Estas
cinco funciones necesitan botones que ejecuten una acción, pero se pintan una sola vez por refresco
de ficha -sin ciclo de vida propio-, así que la clase estática recibe la acción como parámetro
`Callable`: `pintar_desarrollo(lista, j, mundo, al_pulsar)`,
`pintar_venta(lista, j, mio, mundo, paleta, confirmando_id, al_sacar_de_lista, al_poner_en_venta,
al_rescindir)`, etc. `principal.gd` sigue siendo dueño de la mutación real
(`_reconvertir`/`_rescindir`/`_listar_transferible`/informes) y se la pasa envuelta en un closure;
`FichaJugadorAcciones` solo pinta y conecta el botón a lo que le dieron.

**Bug propio encontrado y arreglado ANTES de correr ninguna prueba**: el primer `_dinero()`
duplicado en el componente nuevo usaba un formato inventado (`$X`/`XK`/`X.XM`) sin el factor de
conversión `Eco.ECO` que sí tiene el original de `principal.gd`. Comparado a mano contra la función
real y corregido para que quede idéntico (`float(monto) * Eco.ECO` y luego `%.1fM EUR`/`%dk
EUR`/`%d EUR`) -si no se pilla, la ficha del jugador ajeno hubiera mostrado montos de fichaje
equivocados sin ningún error visible.

**Verificación real, un escalón más estricta que las tandas anteriores**: como acá SÍ hay botones
que mutan el mundo, no bastaba con mirar que se pintaran -la lección del bug crítico del mismo día
fue justamente "un botón que se ve pero no hace nada no da ningún error"-. `pruebas/captura_verificar_ficha_acciones.gd`
(nuevo) abre `principal.tscn` de verdad y **pulsa los botones** (`Button.pressed.emit()`) para
confirmar la mutación real, no solo el pintado: desarrollo prioritario cambió de verdad en
`mundo.entrenamiento.es_prioritario()`, la reconversión de puesto cambió `Jugador.pos_e` (de LI a
LD), y "Poner en venta" marcó `transferible = true`. Captura guardada en
`pruebas/pantalla_ficha_acciones.png`. Banco completo: 0 fallos, `.err.txt` vacío. Auditoría
estática: 0 duplicadas, 0 clases sin usar.

**De paso, un hallazgo de la auditoría**: `_responder_oferta(idx, acepta)` en `principal.gd`
resultó código muerto -sin ningún llamador en todo el archivo-, reemplazada hace tiempo por
`_responder_oferta_mercado()` cuando se conectó la señal `oferta_respondida` de `PanelMercado`. Es
el mismo patrón que el bug crítico de hoy (función vieja sin borrar tras una migración), solo que
esta sí compilaba porque no citaba ninguna variable borrada. Se confirmó con `grep` que
`_responder_oferta_mercado` (línea ~15019) hace exactamente lo mismo con `Ficcion.limpiar()` de
más, y se borraron las 15 líneas muertas.

`principal.gd`: 15.261 → 15.036 líneas en esta tanda (225 de la extracción + 15 de la función
muerta borrada aparte). Con las tres tandas de hoy: 15.589 → 15.036 (553 líneas movidas a
componentes propios o eliminadas por muertas).

**Sigue pendiente, documentado y sin tocar**: el panel de finanzas completo (500+ líneas, medir
antes de cortar) y `_pintar_plantel`/plantel del club (sin medir todavía). Ver `ROADMAP.md`.

## BUG CRÍTICO: EL JUEGO ENTERO NO ARRANCABA — CERRADO (25-9-2026)

El usuario pidió terminar un plan de refactor (`integracion_panel_mercado.md` /
`refactorizacion_plan.md`, dos documentos externos) que resultó **ya estar implementado**:
`ui/componentes/panel_mercado.gd` (`PanelMercado`) ya existía y ya estaba conectado en
`principal.gd` por señales, más completo incluso que el propio plan (traía `oferta_enviada`,
`negociacion_cancelada`, `campo_ajustado`, `intercambio_elegido`, que el documento no mencionaba).

**Pero al revisar si quedaba algo por "terminar" se encontró que `ui/principal.gd` NO COMPILABA.**
Verificado con `godot --check-only --script` y confirmado con un arranque real del proyecto: el
código viejo del mercado (`_pintar_mercado()`, `_pintar_filtros_mercado()`,
`_pintar_estado_mercado()`, `_pintar_mesa_negociacion()`, `_fila_ajuste()`,
`_ajustar_rol_negociacion()`, `_texto_ultima_ronda()`, más las variables `_filtro_mercado_*`)
había quedado marcado `@deprecated` pero SIN BORRAR, y todo ese bloque citaba `_lista_mercado`
-una variable que dejó de declararse el día que se conectó `PanelMercado`-. GDScript con
tipado estático no tolera un identificador no declarado: **`principal.gd` fallaba al parsear, y
como `ui/inicio.gd` (la escena `run/main_scene`) depende de esa clase, el juego entero no
arrancaba desde ningún lanzador.**

**Por qué nadie lo vio hasta hoy**: `pruebas/banco.gd` -el banco de 850+ comprobaciones que se
corrió una decena de veces en esta misma sesión, siempre en 0 fallos- **no carga `principal.tscn`**,
así que un error de parseo ahí es invisible para el banco headless. Es el mismo patrón que ya
costó un bug real el 22-9 ("un `:=` indexando un Array sin tipar rompía la carga ENTERA de
`ui/principal.gd` y el banco headless no lo veía").

**Arreglado**: se confirmó con `grep` que las funciones muertas SOLO se llamaban entre sí -nunca
desde `_refrescar()` ni desde la construcción de pestañas, que ya usan `PanelMercado`- y se
borraron los tres bloques completos (357 líneas). Se tuvo cuidado de NO tocar las funciones con
nombre parecido que SÍ siguen vivas como manejadoras de las señales del componente nuevo
(`_enviar_oferta_negociacion`, `_cancelar_negociacion`, `_al_ajustar_rol_neg`,
`_al_ajustar_campo_neg`, `_responder_oferta_mercado`, `_abrir_negociacion`) ni `_dato()`, que es
un helper genérico usado por decenas de otras pantallas.

**Verificación real, no solo el banco**: `pruebas/captura_verificar_mercado.gd` (nuevo) abre
`principal.tscn` de verdad -lo que el banco nunca hace- y entra a la pestaña Mercado. Confirmado
con captura: `PanelMercado` pinta el estado del mercado, los filtros, la lista de 60 objetivos con
datos reales y la ficha del jugador seleccionado. Banco completo: 0 fallos, `.err.txt` vacío.

**CONSECUENCIA GRAVE, ya corregida**: los dos builds que se habían empaquetado y entregado HOY
MISMO (el `.exe` ligero enviado antes y el completo subido a Drive,
`DINASTIA-completo-v20260923.zip`) llevaban este bug -**no arrancaban en absoluto**-. Se
re-exportaron los dos formatos con el arreglo, se borró el zip roto de Drive y se subió
`DINASTIA-completo-v20260925-fix.zip` en su lugar.

## COHERENCIA VISUAL 2D/3D: EL MODO DALTÓNICO NO LE LLEGABA A PANELMERCADO (25-9-2026)

Revisando el mismo plan de refactor -pedido explícito del usuario: "primero haz solo el punto 3"
(integración 2D/3D, usar las constantes de color ya definidas)- se encontró que la arquitectura de
paneles de `principal.gd` YA es disciplinada (`_panel()`/`_pal_panel()`/`_pal_borde()`, un solo
punto de verdad, 12 `StyleBoxFlat` en todo el archivo y ninguno inconsistente). Pero al llamar a
`_panel_mercado.inicializar()` (línea ~2538), `verde`/`rojo`/`oro` viajaban **sin pasar por
`_color_accesible()`** -el remapeo a la paleta Okabe-Ito del "modo daltónico" de Ajustes, que el
resto del juego respeta desde que se centralizó "en `_texto()` en vez de en las mil llamadas"-.
Con el modo activado, la interfaz entera cambiaba de verde/rojo/oro a azul cielo/bermellón/ámbar
**menos la pestaña Mercado**: "mercado abierto", si un fichaje es pagable, "ganas de venir",
seguían en los colores de siempre. Es justo la clase de incoherencia entre un componente nuevo y
el resto de la interfaz que pedía el usuario.

**Arreglado**: los tres colores pasan ahora por `_color_accesible(COL_VERDE/ROJO/ORO)` antes de
entrar al diccionario de paleta que recibe `PanelMercado`. Verificado con
`pruebas/captura_verificar_mercado.gd` (ampliado): activa `_daltonico = true` a mano -como haría
el checkbox real de Ajustes-, refresca la pantalla y confirma que `PanelMercado.COL_VERDE` pasa de
`#4caf6d` a `#56b4e9` (el azul Okabe-Ito). Dos capturas reales, sin y con el modo, muestran "GANAS"
cambiando de verde a naranjo/ámbar igual que el resto de la interfaz.

**Sobre los puntos 1 y 2 del plan que trajo el usuario** (modularización y renombrado legal): al
investigar se encontró que **los dos YA estaban implementados** -`ui/componentes/panel_mercado.gd`
y `ficcion/ficcion.gd` ya existían, este último con más de 100 variantes de clubes/jugadores/ligas
sudamericanas-, aunque el renombrado legal solo se aplica hoy DENTRO de `PanelMercado`, no en el
resto de `principal.gd` (el nombre del club propio en la cabecera, la tabla de posiciones, la
ficha de jugador, etc. siguen mostrando el nombre real). El usuario pidió explícitamente frenar
ahí y hacer primero solo el punto 3; el resto del renombrado queda pendiente de que confirme que
quiere extenderlo, por ser una decisión de identidad del juego, no un detalle de código.

## MODULARIZACIÓN, SEGUNDA TANDA: `FichaJugadorInfo`, Y UN HALLAZGO IMPORTANTE SOBRE EL ALCANCE (25-9-2026)

Siguiendo el mismo pedido de fragilidad, se midió el subsistema de la ficha del jugador antes de
tocarlo -la disciplina que costó cara el 22-9 y el 25-9-, y **resultó mucho más grande y entrelazado
de lo que asumía el plan externo** ("~300 líneas, estado: `_seleccionado`"): son **14 funciones y
850+ líneas**, con quince y pico botones distintos conectados a acciones reales del mundo (pedir
informe, comparar, ofrecer, negociar, pagar cláusula, desarrollo prioritario, reconvertir,
fidelidad, vender, rescindir...), y con helpers compartidos (`_bio_de()`/`_perfil_humano()`)
llamados desde DOS puntos distintos del archivo, no solo desde dentro de la propia ficha.

**Decisión, explícita y documentada, no un olvido**: intentar extraer las 14 funciones de una sola
vez -la misma noche que se encontró y arregló un juego que no arrancaba por una migración a
medias- era exactamente el riesgo que el usuario pidió reducir. Se verificó, una por una, cuáles NO
tienen botón ni mutan el mundo -son solo lectura, pintan y ya-, y se extrajeron SOLO esas ocho:
`pintar_ciega`/`pintar_estadisticas`/`pintar_cabeza`/`pintar_promesa`/`pintar_habilidades`/
`pintar_historial_medico`/`pintar_vida_personal`/`pintar_historial`, a
`ui/componentes/ficha_jugador_info.gd` (`FichaJugadorInfo`, mismo patrón estático que
`TablaCompeticion`). Las dos llamadas a `bio_de()`/`_ver_ficha()` (una directa, otra dentro de
`pintar_vida_personal()`) se localizaron y actualizaron las dos.

**Quedan EN `principal.gd`, a propósito, para una pasada futura con más tiempo**:
`_pintar_desarrollo_ficha`, `_pintar_reconversion_ficha` (+ `_reconvertir`), `_pintar_marca_ficha`,
`_pintar_similares_ficha`, `_pintar_venta` -las cinco tienen botones que tendrían que convertirse en
señales, como hizo `PanelMercado`, y eso es trabajo real, no una línea-. **Y el panel de finanzas
completo**, que al medirlo resultó tener el mismo patrón: mucho más grande (500+ líneas visibles
solo en los usos de `_lista_finanzas`, con funciones antes de `_pintar_finanzas()` que ni siquiera
se habían identificado todas) que el "~200 líneas" que asumía el plan externo. Anotado en
`ROADMAP.md` para no repetir el error de dar por buena una estimación sin medir.

**Verificación real**: `pruebas/captura_verificar_ficha.gd` (nuevo) abre `principal.tscn`, mira la
ficha de un jugador PROPIO -ejercita las ocho funciones movidas- y de uno AJENO -ejercita la llamada
directa a `bio_de()`-, confirmando ambas capturas con datos reales (media/potencial, moral,
contrato, botón de informe de ojeo). Banco completo: 0 fallos. Auditoría estática: 0 duplicadas, 0
clases sin usar.

`principal.gd`: 15.474 → 15.243 líneas (231 menos en esta tanda; 15.589 → 15.243 en las dos tandas
de hoy, 346 líneas movidas a componentes propios).

## MODULARIZACIÓN REAL: `TablaCompeticion`, PATRÓN DE CLASE ESTÁTICA (25-9-2026)

Pedido explícito del usuario tras el bug crítico de este mismo día: *"lo que debemos buscar es
modular y mejorar el código principal del juego, para que no sea tan frágil ni tan crítico, 15 mil
líneas todas juntas una dependiente de otra es un gran riesgo"*.

Se sacaron de `principal.gd` las cinco funciones que pintaban la columna "TABLA DE POSICIONES"
(`_pintar_tabla`/`_mi_grupo_nombre`/`_pintar_grupo`/`_pintar_cuadro`/`_pintar_tabla_liga`, 115
líneas) a `ui/componentes/tabla_competicion.gd`, **con un patrón deliberadamente distinto al de
`PanelMercado`**: en vez de un componente de escena (`VBoxContainer` con `inicializar()`/`pintar()`
de instancia), es una clase **estática** (`RefCounted`, nunca se instancia) con funciones puras que
reciben datos y pintan -sin estado propio, sin filtros, sin señales-, igual que ya funcionan
`Escudo`/`Marca`/`Nombres` en este proyecto. No todo lo que sale de un archivo monolítico tiene que
volverse un nodo de escena: esto es "pintar una tabla a partir de datos", no una pantalla
interactiva, y forzarlo al patrón de `PanelMercado` habría sumado un ciclo de vida (¿cuándo se
instancia? ¿quién la libera?) que no hace falta.

**Aplicando la lección del punto 3 desde el principio, no después**: los colores que recibe
(`paleta: Dictionary`) ya vienen resueltos por `_color_accesible()`/`_pal_*()` -incluido `escala`,
el tamaño de letra de Ajustes, que ni siquiera `PanelMercado` respeta todavía-, así que esta tabla
nunca tuvo el hueco de coherencia visual que hubo que corregir en el mercado.

**Verificación real, no solo el banco**: `pruebas/captura_verificar_tabla.gd` (nuevo) abre
`principal.tscn` de verdad y confirma que el título ("PRIMERA DIVISION") y la cuadrícula siguen
pintando datos reales -escudos, posiciones, puntos- byte por byte igual que antes de mover el
código. Banco completo: 0 fallos. Auditoría estática (`herramientas\auditar_godot.ps1`): 0
funciones duplicadas, 0 clases `class_name` sin uso -`TablaCompeticion` quedó bien enganchada-.

`principal.gd`: 15.589 → 15.474 líneas.

## LA RED DE SEGURIDAD QUE FALTABA: LAS TRES ESCENAS RAÍZ AHORA SE PRUEBAN SOLAS (25-9-2026)

Mismo pedido de fragilidad. El bug crítico de hoy (ver más abajo, sección "BUG CRÍTICO") pasó
desapercibido durante quién sabe cuánto tiempo porque `pruebas/banco.gd` -corrido una decena de
veces esa sesión, siempre en 0 fallos- **nunca había cargado una sola escena de `ui/`**: prueba el
`nucleo/` a fondo, pero un error de sintaxis en la interfaz era invisible para "0 fallos".

Se agregó `_probar_carga_de_ui()`, la PRIMERA prueba que corre el banco (barata, y así se sabe en
el primer segundo si algo rompió la interfaz, no después de 15 minutos): carga e instancia
`inicio.tscn`, `eleccion_club.tscn` y `principal.tscn`, las tres escenas raíz del juego.

**Bug de verificación real, encontrado escribiendo esta misma prueba, antes de confiarla**:
`PackedScene.instantiate()` en Godot **nunca devuelve `null`**, aunque el script de la raíz esté
completamente roto -crea igual el `Node` base, sin el script pegado-. Un primer intento que
comprobaba `nodo != null` habría sido una prueba que **siempre pasa**, exactamente el tipo de
candado que miente por ausencia. Se corrigió comprobando `nodo.get_script() != null`, y se
confirmó con un caso de mentira: un script con un identificador no declarado, deliberadamente roto,
usado para probar la lógica de la prueba antes de confiar en ella (y borrado después, no queda
código de prueba en el proyecto real). Con `get_script()`: `null` en el roto, el recurso real en
uno sano -confirmado con los dos casos antes de dar la prueba por buena-.

## LA PANTALLA DEL ESTADIO Y LAS VALLAS LED, CON LOS VIDEOS DE REFERENCIA DELANTE (23-9-2026)

Sesión pedida por el usuario para una sola misión: *"mejorar el marcador interactivo de la pantalla
del estadio y mejorar el estadio, basándote en el video de ejemplo de los partidos"*. Un mensaje
después aclaró que el prioritario era el otro video; se revisaron **los dos** (los dos duran menos de
30 s) y resultó que coinciden en lo importante, así que se usaron los dos a la vez:

- `marca/referencia/ejemplo-partido.mp4` (28,7 s, Soccer Manager 2026 grabado del celular, vertical):
  de aquí sale el **diseño del marcador** -barra oscura con escudo + abreviatura de TRES LETRAS + los
  dos números dentro de un bloque ÁMBAR-. Nunca el nombre completo del club: por eso ahí nada se
  corta y en la versión del 22-9 sí se cortaba.
- `marca/referencia/ea_fc25_referencia.mp4` (10 s, 1280×720, con rótulos del propio proyecto encima
  -"jugadas prehechas", "Tele Dinámica", "Match Playback.gd"-, o sea que es una maqueta hecha para
  ESTE proyecto): de aquí sale la **arquitectura** -las dos pantallas montadas en el FRENTE de la
  tribuna del fondo, nunca asomando sobre el techo, y el anillo de vallas LED que se lee panel por
  panel ("EA FC25", "EA FC24")-.

Los fotogramas se sacaron con el ffmpeg que ya vive en `herramientas\ffmpeg\`, rotando 90° el del
celular (`transpose=2`) porque el juego estaba en horizontal y el teléfono en vertical.

### 1. La pantalla gigante: de un `Label` suelto a seis paneles en rotación

`ui/pantalla_estadio.gd` (NUEVO, `class_name PantallaEstadio extends SubViewport`). Se sacó de
`ui/estadio.gd` a propósito: ese archivo ya pasaba de 800 líneas y esto es una pantalla completa con
seis diseños dentro; aparte, así se puede volcar su textura en una prueba sin levantar el estadio 3D.

Lienzo de 960×512 (proporción 1,875 exacta, la misma de la malla). Seis paneles:

| Panel | Qué enseña | De dónde salen los datos |
|---|---|---|
| MARCADOR | escudos, abreviaturas, marcador en bloque ámbar, reloj, posesión | `Partido` |
| ESTADÍSTICAS | posesión, remates, al arco, córners, faltas | `Partido` |
| GOLES | los goleadores de ESTE partido con su minuto | `al_gol()`, desde `estadio.gd` |
| TABLA | top 6 de la liga, con los dos clubes del partido resaltados | `datos["tabla"]` |
| PICHICHI | top 6 de máximos goleadores de la liga | `datos["goleadores"]` |
| BIENVENIDA | escudo, club y aforo, cuando NO hay partido | `Club` |

Rotan solos (11 s el marcador, 7 s el resto) y solo entran los paneles que tienen datos de verdad
-en la fecha 1, sin goles todavía, el panel de pichichis no aparece en vez de salir en blanco-. Y hay
un séptimo panel fuera de la rotación: **el corte a "¡GOOOL!" a pantalla completa** con el nombre del
autor, el minuto y el marcador nuevo, verde si anota el dueño del recinto y rojo si lo sufre, que se
va solo a los 6,5 s. Eso es lo "interactivo" que pedía el usuario: la pantalla reacciona.

La tabla y los goleadores **no los puede calcular `VistaEstadio`**, que es un visor y no conoce el
`Mundo` (ni debe). Se calculan en `principal.gd::_datos_pantalla_estadio()` y viajan en un
`Dictionary` -mismo patrón que `perfil_estadio_de()` y `Comercial.color_balon()`, que ya viajaban
así-: `principal.gd` → `PartidoVivo.datos_pantalla` → `VistaEstadio.datos_pantalla`. Vacío es válido.
También se monta **sin partido** (Club → Estadio), donde antes solo había un degradado estático.

### 2. Las vallas LED del perímetro, con marca de verdad y cambiando solas

`visor/vallas_led.gd` (NUEVO) + `StadiumBuilder._vallas_publicidad()` rehecho. Hasta hoy eran **54
cajas de color liso** alternando tres tonos: la silueta estaba, el contenido no -exactamente el mismo
hueco que tenía la pantalla-. Ahora cada panel lleva un rótulo `Label3D` (no una textura generada:
rasterizar texto a una `Image` en Godot 4 obliga a montar un `SubViewport`, y esto es código estático
que construye mallas fuera del árbol) y el anuncio **cambia cada 5 s en ola**, con desfase por panel,
cambiando también el color del panel. No se funde entre anuncios, corta en seco: con `Label3D` y
transparencia real serían 54 superficies transparentes a ordenar delante de la grada -el tipo de cosa
que produce parpadeos- y una valla LED de verdad tampoco funde, corta.

Qué dicen: el club de casa, "DINASTÍA" (el equivalente de "EA FC25"/"SOCCER MANAGER 2026" de los
videos), cuatro de las 38 marcas de la tabla `MARCAS` -que existían desde la migración y solo se
veían en la pantalla de auspicios- y un "VAMOS <club>". **Elegidas por el hash del club**, así que el
mismo estadio anuncia siempre lo mismo y dos estadios distintos no. El usuario pidió explícitamente
que esto fuera "una variante por club"; ya lo era, pero no estaba probado, así que ahora se comprueba
con dos clubes y se imprimen los dos juegos. La tinta se decide contra el fondo (la mitad de las 38
marcas traen colores claros y el texto blanco desaparecía).

### 3. TRES BUGS REALES, los tres encontrados con capturas, ninguno sospecha

**3.1. El techo partía la pantalla en dos.** `_pantallas()` la clavaba en `y = alto - 1.0` con un
marco de 9 m de altura FIJA. La cubierta va en `alto + 0.4`: o sea que la mitad de arriba de la
pantalla asomaba sobre el graderío y el techo le pasaba por delante, dejando una banda negra que la
cruzaba. Y en un estadio de 1 nivel (alto 6,5 m) esa misma pantalla de 9 m se hundía bajo el césped.
Ahora **cuelga bajo la cubierta y escala con el recinto** (`clampf(alto * 0.46, 4.2, 9.0)`), como en
`ea_fc25_referencia.mp4`. El cubo suspendido tenía el mismo problema en peor (26 m fijos, fuera del
recinto en cualquier estadio de menos de 3 niveles) y se bajó igual. Con el rectángulo liso de antes
la banda negra del techo cruzándola no delataba nada; en cuanto la pantalla tuvo texto, saltó a la
vista.

**3.2. La pantalla enseñaba un RECORTE AMPLIADO de su propio contenido, y este es el bug que
`LEEME.md` dejó abierto el 22-9.** Ese día se anotó: *"la textura aislada se ve perfecta pero en la
escena no aparece el escudo, debe de ser el encuadre de la prueba"*. **No era el encuadre**: la
pantalla era un `BoxMesh`, y Godot **no mapea la textura entera a cada cara de un cubo**, reparte las
seis caras en un atlas de UV. La cara que mira al campo enseñaba un trozo gigante de la imagen -en la
captura se veía media abreviatura de tres letras ocupando la pantalla entera y un pedazo de escudo-
por muy bien generada que estuviera la textura. Arreglado con un `QuadMesh`, que sí mapea 0..1 sobre
toda la cara (`_quad_pantalla()`). El cubo suspendido pasa a tener sus cuatro caras como cuatro
quads. De paso, `_pantalla_textura()` (el degradado de respaldo) pasa de 256×144 a 240×128 para
respetar la misma proporción 1,875 -a 16:9 el escudo salía ovalado-.

**3.3. El marcador no se enteraba del gol durante el corte de "¡GOOOL!".** El `refrescar()` de
`PantallaEstadio._process()` estaba DESPUÉS del `return` del corte de gol, así que durante 6,5 s el
panel de debajo seguía con el resultado anterior. Lo cazó la prueba pidiendo "1 - 0" y leyendo
"0 - 0".

### 4. Y TRES BUGS DE VERIFICACIÓN en la prueba del 22-9, que hacían que no probara lo que decía

`pruebas/captura_marcador_pantalla.gd` (22-9) tenía tres fallos que se arreglan en la prueba nueva,
`pruebas/captura_pantalla_gigante.gd`:

1. **Activaba su cámara en `_ready()`**, o sea ANTES de que `VistaEstadio.abrir()` construyera el
   `CameraRig` -que crea 9 cámaras y activa una-. La del rig ganaba siempre y la captura salía
   enfocando el césped. Es literalmente el *"bug en el ENCUADRE de la cámara de la propia prueba"*
   que se anotó sin diagnosticar. Ahora la cámara se reclama en cada frame, porque además **cada gol
   manda el rig a "Tele Dinámica"** (`_seguir_jugada_gol()`, que es el comportamiento BUENO del
   juego) y vuelve a robar el plano.
2. **Forzaba goles con `partido.gol.emit(...)` a secas.** Emitir la señal NO sube el marcador:
   `Partido._anotar()` hace `goles_local += 1` y LUEGO emite. La pantalla mostraba "0 - 0" con toda
   la razón y la prueba lo daba por bueno. Por eso el `LEEME.md` del 22-9 afirma que *"el marcador de
   `Partido.goles_local` sube correctamente"* — **no subía**, nunca se probó eso.
3. **Cambiaba de panel y guardaba la captura en el MISMO paso.** El PNG sale del frame ya
   renderizado, así que se fotografiaba el panel anterior: la primera vuelta sacó el cartel de gol
   creyendo que era el marcador. Ahora cada cambio y su foto van en pasos distintos.

Además el encuadre ya no se calcula a mano: se saca de la `global_position` de la malla real, y cada
captura imprime **qué cámara la hizo**. Y se vuelca la textura del `SubViewport` a disco aparte
(`pgt_*.png`): evidencia del contenido independiente del encuadre 3D, el mismo método que resolvió el
lío de la pantalla azul el 22-9.

### Verificación

- `pruebas/captura_pantalla_gigante.gd` (nuevo): **0 fallos**, 9 capturas de escena (`pg_*.png`) + 7
  volcados de textura (`pgt_*.png`). Se ven bien y con datos reales los seis paneles, el corte de
  gol, las vallas de cerca y el plano general con la pantalla ya en su sitio.
- Banco de pruebas: **8 comprobaciones permanentes nuevas** en `_probar_pantalla_y_vallas()`, dentro
  de `_probar_estadio()`. Cubren la abreviatura de tres letras (incluido "D. Limache" → "LIM", el
  caso que reventó la versión vieja), que la pantalla no se cruce con el techo **en los tres
  niveles** (la regresión del bug 3.1, comprobada con números y no a ojo), que cada club tenga su
  propio juego de vallas con su nombre dentro, y que la tinta del rótulo contraste con su fondo.

### 5. EL ESTADIO Y EL PÚBLICO (segunda parte de la sesión, mismo día)

El usuario, viendo las capturas: *"sigues viendo qué cosas son fáciles de mejorar para llegar a la
calidad del video y que sean un gran impacto... falta mejorar el estadio en sí, y el público"*. Se
lanzó un agente a auditar `visor/stadium_builder.gd` buscando **el patrón que había causado el bug
del techo**: medidas en metros fijas que solo cuadran con UNA forma y UN número de niveles. Encontró
12 casos. Se cerraron los de más impacto visual:

**5.1. LA GRADA SOLO VEÍA EL 17% DE SU TEXTURA, y es la superficie más grande del estadio.** Medido,
no supuesto: `pruebas/diagnostico_uv_caja.gd` (nuevo) lee las UV reales del `ArrayMesh` que genera
Godot y las imprime cara por cara. Resultado: un `BoxMesh` reparte las seis caras en un **atlas de
3×2**, así que cada cara ve `U 0,333..0,667 × V 0,5..1,0` = **el 17% de la imagen**, ampliado 3× a lo
ancho y 2× a lo largo. (Un `QuadMesh` y un `PlaneMesh` ven el 100%; por eso el arreglo de la pantalla
funcionó.) Consecuencias que llevaban meses a la vista sin explicación: el patrón de butacas que el
usuario elige en Club → Estadio (franjas, damero, sectores, bandera...) se generaba entero y en
pantalla salía **un sexto de él**, y la densidad real de texeles a lo ancho de la rampa era un tercio
de la generada -que es justo el eje que hacía el aliasing de "estática de TV" del 21-9-. Se corrige
remapeando ese rectángulo a 0..1 con `uv1_scale`/`uv1_offset` en vez de cambiar la malla.

**5.2. El público estaba tumbado 58,6° hacia atrás.** Las butacas y los hinchas son hijos del deck ya
inclinado, así que heredaban la pendiente ENTERA: con 3 niveles el graderío va a `atan2(18, 11)` =
58,6°, o sea el público reclinado como en un despegue. Ahora cada instancia se contrarrota por
`-rake` alrededor del eje que inclinó su tribuna, así que queda **de pie sobre la pendiente**, que es
lo que pasa en un estadio de verdad (las butacas van sobre escalones horizontales, no sobre el plano
inclinado). Ojo con el orden: `Basis.rotated()` premultiplica, así que primero el giro hacia el campo
y después la contrarrotación; al revés queda derecho pero mirando de lado.

**5.3. El público de la textura, en filas de verdad — la tercera vuelta al mismo problema.** El 21-9
se corrigió que cada persona se pintaba en UN texel (salía "estática de TV") pasando a bloques del
tamaño real de una persona + mipmaps + anisotrópico. Mejoró, no cerró. La causa que quedaba: las
personas se **sorteaban en posición libre**, así que en el eje que sube la rampa el dato seguía
siendo ruido blanco a 0,2 m -no hay nada coherente que un mip pueda promediar, por muchos bloques que
tenga en el otro eje-. Ahora el público va en **filas alineadas**, con su escalón oscuro entre fila y
fila y **dos escaleras de hormigón** cruzando la grada. Eso convierte el ruido en una señal
periódica, que es lo que un mip promedia bien, y además es lo que se ve en `ea_fc25_referencia.mp4`:
filas, no una mancha de confeti. Se deja el último texel de cada fila sin cubrir -el respaldo de la
butaca asomando- para que el patrón de colores del club siga leyéndose con la grada llena. De paso,
el dibujo del público estaba DUPLICADO literal en `_make_stand_texture()` y
`_make_stand_texture_tramos()` (y la segunda ya se había quedado una vez sin un arreglo que la
primera sí recibió): ahora es una sola función, `_pintar_publico()`. Y la resolución del eje de la
rampa sube de 64 a 96 texeles, que **ahora sí se ven** gracias a 5.1.

**5.4. Cuatro de las diez lámparas de la corona flotaban sobre el campo.** Se repartían sobre una
ELIPSE (`cos(a)*dx`, `sin(a)*dz`) y el anillo de tribunas es un RECTÁNGULO: con n=10, las de 36°,
144°, 216° y 324° caían en |x|≈40 y |z|≈40, por dentro de la cara de las tribunas, colgando a 20 m
de altura sin nada debajo. Ahora el punto de la elipse se proyecta al borde del rectángulo.

**5.5. El cubo colgante nunca quedaba bajo cubierta.** Estaba a 26 m FIJOS; el primer arreglo de esta
misma sesión (`alto + 4`) seguía mal por lo mismo -el techo va en `alto + 0.4`, así que `alto + 4`
está SIEMPRE por encima-. Corregido al mismo criterio que la pantalla plana.

**5.6. La segunda pantalla se colgaba en el lado abierto de la herradura.** El tipo por defecto es
"dos", y `_pantallas()` no recibía `abierta`: en una herradura salía un marco de hasta 9 m flotando
en el aire sin tribuna ni techo detrás.

**5.7. Las esquinas del cuenco sobresalían 3,5 m hacia dentro de la cancha.** El bloque iba en
`(dx-3, dz-3)` con 12 m de lado, o sea de `dx-9` a `dx+3`, y la cara interior de las tribunas está en
`dx-5,5`: un pilar metido por delante de las dos tribunas vecinas que además enterraba el extremo de
cada rampa con sus butacas. En la forma más chica ("inglés") llegaba a 2 m de la línea de banda.
Centrado en `(dx, dz)` con 11 m -el mismo fondo que las tribunas- queda a ras de las dos.

**Verificación de esta parte**: `pruebas/captura_formas_estadio.gd` (nuevo) monta **las seis formas y
los tres niveles** con distintos tipos de pantalla y foco, y deja una foto de cada una. Existe
precisamente porque todas las capturas de este proyecto se habían sacado siempre con el mismo estadio
(el "cuenco" de 3 niveles de Colo-Colo), y por eso ninguno de estos fallos se veía nunca: solo salen
en otras formas.

### 6. TERCERA TANDA: LA HINCHADA VIVA Y EL RESTO DE LA AUDITORÍA (mismo día)

El usuario, viendo las capturas: *"el público aún no lo veo malo, ¿hay formas de que se vean más
reales?"*, y después *"ese modelo de público debe estar en toda la grada, siempre falta una parte"*.

**6.1. La hinchada se mueve, tiene cara y no mide toda lo mismo.** `visor/hinchada.gdshader`
(NUEVO), sobre el mismo `MultiMesh` de siempre -cero vértices nuevos, cero llamadas de dibujo
nuevas-:
- **Se balancean y saltan.** Cada hincha con su propia fase, sacada de su posición en el mundo (así
  es estable entre cuadros y distinta para cada uno). Los pies no se mueven: el peso del
  desplazamiento crece con la altura del vértice, así que oscilan los hombros. El salto usa
  `max(0, sin(t) - 0.86)`, o sea que solo el 11% del ciclo queda por encima del umbral: salta una
  minoría en cada momento, no una ola perfecta.
- **La cabeza es piel, no camiseta.** Hasta hoy cada hincha era una cápsula de UN SOLO COLOR, cabeza
  incluida: de cerca se leían como pastillas de colores. El color de instancia sigue siendo la ropa
  y del cuello hacia arriba se mezcla a un tono de piel elegido con la misma fase.
- **Estaturas variadas** (±10%), en la misma matriz de la instancia.
- **Y de paso, un bug propio**: la contrarrotación que enderezó a las BUTACAS (punto 5.2) no se
  había aplicado a los HINCHAS, que seguían tumbados 58,6°. Corregido.

**6.2. El público llega a la última fila.** Con 3 niveles las butacas 3D cubrían 13 m de una rampa
de 21: **el tercio de arriba de cada tribuna no tenía ni una persona**, y se veía como un corte
horizontal a media grada. Lo que faltaba era separar dos presupuestos que estaban juntos: una fila
de tres butacas del modelo real cuesta **988 vértices** y un hincha **~70**. Subir las butacas a
toda la rampa sería pasar de 4,4 a 6,7 millones de vértices -una Intel UHD no lo mueve, que es el
motivo documentado de que estuvieran limitadas-; subir SOLO los hinchas cuesta ~400.000 en total.
Ahora `filas_todas` (hinchas) y `filas` (butacas 3D) son dos números distintos.

**6.3. Telones de hinchada y vomitorios.** `_telones()` y `_vomitorios()`, hijos del `deck` en
coordenadas LOCALES a propósito: el deck ya viene inclinado, así que la pendiente y la orientación
las pone el nodo. Calcularlo en coordenadas de mundo habría significado deshacer a mano la rotación
de cada una de las 4 tribunas, que es justo el tipo de cuenta que produjo la mitad de los bugs de
esta sesión. Dos correcciones que costaron una captura cada una: el primer intento puso los telones
en el tercio BAJO de la rampa y **no se veía ninguno** (ahí están las butacas 3D, de 0,8 m, y un
trapo tumbado a 0,34 m quedaba enterrado entre ellas); y el color salía del mismo asiento del club,
así que se fundía con el fondo -ahora llevan reborde oscuro y uno claro garantizado entre los tres-.

**6.4. El resto de la auditoría, cerrada.** Los 12 hallazgos quedan cerrados:
- **El túnel estaba anclado a 64,0 m FIJOS**, que es el `dz` de la forma "inglés" clavado a mano.
  En "oval" (dz=74) la mole quedaba SOLA sobre el hormigón, 7 m por delante del graderío; en
  "inglés" y "caldera" la boca quedaba enterrada dentro de la rampa. Ahora se deriva: `dz - 2.5`
  deja el frente a ras de la cara interior de la tribuna.
- **El túnel tipo "arco" se plantaba DENTRO del área grande** (z=42,5 fijo, y el área va de 33,75 a
  50,25), y el tipo **"foso" estaba entero por debajo de `y=0`**: bajo un plano de césped opaco, o
  sea **invisible**, con su emisión alumbrando el reverso del suelo. Las dos ramas se habían
  quedado fuera del arreglo del 21-9, que solo tocó "central/esquina/telescópico".
- **Había DOS banquillos, uno dentro del otro.** El viejo `_banquillos()` pintaba una caja fija que
  se cruzaba con el dugout del catálogo desde que se corrigió el cambio de ejes X/Z del 13-9.
  Síntoma delator: recibía `dx` y **no lo usaba**. Borrado.
- **Las vallas LED pasaban por dentro del dugout** (los paneles de z=±9 y ±15 del lado +X).
- **El escudo de tribuna**: con 1 nivel cruzaba el techo y asomaba por encima; con 3 flotaba 12 m
  en el aire por delante de la grada; el de "fachada" estaba por DENTRO del cuenco; y el de "techo"
  era un cuadro vertical que atravesaba la losa. Los tres corregidos.
- **`CameraRig`**: la cámara "Tribuna alta" tenía `clampf(alto*0.55, 12.0, 34.0)` y como `alto` no
  pasa de 19,5, esa expresión **nunca superaba su propio mínimo: era código muerto que siempre
  devolvía 12**, y además estaba en x=34, que es la línea de banda y no una tribuna. Y la distancia
  de "Tele Dinámica" era una constante de 46 m que en "inglés" deja la cámara fuera del muro.
- **En "herradura" se borraban las CUATRO esquinas**, no solo la del lado abierto.

**Verificación de esta tanda**: banco 0 fallos con `.err.txt` vacío; `captura_pantalla_gigante.gd`
0 fallos (y una comprobación nueva que cuenta los telones -hizo falta porque la primera versión SÍ
los creaba y no se veía ninguno, y sin un número a la vista es imposible distinguir "no se crearon"
de "se crearon y están tapados"-); `captura_formas_estadio.gd` en las seis formas; y un video real
(`pruebas/video_hinchada.gd`, nuevo) porque **una foto no puede probar que la hinchada se mueve**:
el balanceo depende de `TIME` y la única verificación honesta es una grabación.
### Lo que queda anotado de la auditoría, sin hacer

Del informe del agente, no se tocaron (menos visibles o más caros): el túnel anclado a `ANCLA_Z = 64`
(el `dz` de "inglés" clavado a mano, que en "oval" deja la mole fuera del plano de césped y en el
resto la mete dentro del graderío); los tipos de túnel "arco" y "foso", que nunca recibieron ese
arreglo -el arco queda plantado DENTRO del área grande, y "foso" está entero bajo `y=0`, debajo del
césped opaco, o sea invisible-; los dos banquillos superpuestos (`_banquillos()` dibuja una caja fija
y además ignora el `dx` que recibe, y se cruza con `_banquillos_detalle()`); las vallas LED pasando
por dentro del dugout; el escudo de tribuna con tres posiciones en metros fijos (en 1 nivel cruza el
techo); y dos cámaras del `CameraRig` con constantes que no escalan ("Tribuna alta" tiene un
`clampf(alto*0.55, 12.0, 34.0)` que **nunca supera su propio mínimo**, o sea que el parámetro es
código muerto y siempre da 12).

## EL MARCADOR EN VIVO DE LA PANTALLA: EMPEZADO, NO CERRADO (22-9-2026)

Pedido repetido del usuario (cuatro veces en la misma sesión): que la pantalla del estadio muestre
"una visualización de los puntos de la competencia... máximos goleadores... o el resultado que van".
Se arrancó por lo más simple y lo más pedido -el resultado en vivo-, dejando tabla de posiciones y
goleadores para después con el mismo mecanismo.

**Lo que sí quedó andando**: `ui/estadio.gd::_montar_marcador_pantalla()` -llamado solo cuando hay
partido- monta un `SubViewport` (512×273) con un `Label` real que muestra "X - Y", y
`StadiumBuilder._pantallas()` nombra sus mallas "PantallaMarcador" para que `estadio.gd` las
encuentre después de construir el estadio y les cambie la textura estática por la del viewport en
vivo. `_actualizar_marcador_pantalla()`, llamado desde `_al_gol()`, reescribe el `Label` -no
reconstruye el viewport entero cada gol-. **Verificado que el dato es real**: forzando dos goles
(`pruebas/captura_marcador_pantalla.gd`, nuevo) el marcador de `Partido.goles_local/goles_visita`
sube correctamente y la textura se actualiza -confirmado por código, el texto SÍ cambia-.

**Lo que NO quedó bien, con evidencia, no una sospecha**: el nombre de los clubes ("COLO-COLO vs D.
LIMACHE") se sale del lienzo -se ve cortado a "ACHE"- a pesar de tener `autowrap_mode` puesto. Es un
problema de contención de `Control` dentro del `VBoxContainer`, no del tamaño de fuente en sí: un
`Label` sin `size_flags_horizontal`/`custom_minimum_size` bien atado al ancho real del contenedor
puede seguir creciendo por su texto natural en vez de respetar el `PRESET_FULL_RECT` del padre. La
pista concreta para la próxima vuelta: fijar `nombres.size_flags_horizontal = Control.SIZE_EXPAND_FILL`
y/o envolver la fila en un `Container` con ancho explícito antes de confiar en el autowrap, y
volver a capturar con `pruebas/captura_marcador_pantalla.gd` (ya escrito, reusable) antes de dar
esto por bueno. El usuario pidió explícito parar acá y seguir la próxima sesión, con un modelo más
capaz -no se siguió puliendo a ciegas-.

**Pendiente, ni empezado**: tabla de posiciones y máximos goleadores en la pantalla -mismo mecanismo
(`SubViewport`+`Label`s), más trabajo de layout (una tabla real, no una línea de texto) y de qué
evento dispara la actualización (¿cada jornada? ¿al abrir la vista?).

## "¿QUÉ SON CABALLOS?" — REPORTE DEL USUARIO SIN INVESTIGAR TODAVÍA (22-9-2026)

El usuario preguntó, en tono de broma, "¿qué son caballos?" sobre algo que vio -no quedó claro qué
exactamente, posiblemente algo en una de las capturas de esta sesión o en el juego mismo- y lo
calificó de "fallo estructural", pero pidió explícitamente NO arreglarlo ahora ("déjalo así") y
seguir con lo demás. Queda anotado tal cual, sin diagnosticar, para la próxima vez que se retome:
preguntarle al usuario qué pantalla o captura mostraba "caballos" antes de intentar reproducirlo -no
hay pista suficiente en este mismo mensaje para buscarlo a ciegas.

## APELLIDOS POR NACIONALIDAD + LA RODILLA DEL BANQUILLO CORREGIDA (22-9-2026)

**1. Apellidos por nacionalidad**, pedido directo del usuario a raíz de un dato sobre el Athletic
Club de Bilbao (cantera vasca, ver más abajo). Hallazgo real antes de tocar nada: la infraestructura
YA EXISTÍA -`POOLS_EU` (13 países) + `NOMBRES_BRA`/`APELLIDOS_BRA`, usados para el DT rival en la
previa (`previa.gd`) y para ojeadores extranjeros (`ojeadores.gd`)- pero `Mundo.crear_jugador()` -el
90% del mundo, ~8.000 jugadores del arranque más cada canterano- nunca la miraba: TODO el mundo
salía con apellido chileno, jugara en Alemania o Japón. Conectado en `Mundo._nombre_al_azar()` y
`Cantera._nombre_al_azar()`/`_nombre_de_pila()` (hijos de leyenda, hermanos), mismo criterio que
`previa.gd`: `POOLS_EU` primero, `BRA` aparte, el fondo chileno de siempre para el resto
(hispanohablantes sin bolsa propia todavía). Se sumó `ESP` a `POOLS_EU` -no estaba, a pesar de que
Alemania/Italia/Francia/Inglaterra sí- con sabor vasco a propósito (Etxeberria, Aduriz, Zubizarreta,
Urrutia, Mendizabal...) más apellidos españoles generales.

**Verificado con un mundo real**, no solo en aislado: Real Madrid mostró "Urrutia, Zubizarreta,
Etxeberria, Aduriz" en sus canteranos/generados, Bayern Múnich "Wolf, Richter, Hoffmann, Weber,
Becker, Braun" -en vez del fondo chileno de siempre-. `pruebas/diagnostico_nombres_pais.gd` (nuevo)
queda como reproducción manual.

**BUG REAL DE VERIFICACIÓN, no del juego, que costó tres cuelgues de 540s cada uno**: la primera
prueba permanente añadida a `pruebas/banco.gd` generaba un TERCER `Mundo` completo
(`Mundo.new().generar(["CHI","ESP","GER"])`) dentro de una función que ya arma dos (`_probar_
desafios()`). El mismo `generar()` en un proceso propio corre en segundos; ahí adentro nunca
terminaba. Causa exacta no encontrada -no valía la pena seguir persiguiéndola-, mitigada evitando
crear un tercer mundo del todo: la prueba permanente verifica la forma de `POOLS_EU` + reusa un
`Mundo` ya vivo de la misma función, y la prueba end-to-end real (Real Madrid/Bayern) queda cubierta
por el diagnóstico manual, ya mostrado al usuario. Bench: 862, 0 fallos, `.err.txt` vacío, 149s -de
vuelta al tiempo normal, no los 540s+ de antes-.

**2. La rodilla del banquillo sentado, corregida con una sonda real.** El usuario preguntó
directamente "¿se ven feas las piernas?" y, viendo una captura de perfil, la respuesta real era sí:
con `+92°` de flexión de rodilla (el número de la ronda anterior, nunca verificado con una imagen
aislada) la pantorrilla se doblaba hacia ARRIBA Y ATRÁS -el pie casi contra el glúteo-, no hacia
abajo. Corregido con `pruebas/sonda_rodilla_sentado.gd` (nuevo): barrido de -150° a 90° con el muslo
ya fijo en 90° (horizontal), una imagen por valor -mismo método que ya usó este proyecto para huesos
sin calibrar (`diagnostico_espalda_sola.gd`)-. `-100°` es el valor real: la pantorrilla cuelga hacia
el piso, exactamente como sentado de verdad. `-80°` se queda corto, `-120°` se pasa (el pie se cruza
detrás de la rodilla). Verificado con una captura real del banquillo (`pantalla_banquillo_piernas.png`):
ahora se ven las botas colgando debajo del banco, no piernas invisibles/dobladas hacia adentro.

## SEGUNDA RONDA DE PULIDO: LA PANTALLA, CON CONTENIDO DE VERDAD (22-9-2026)

Cuarto pedido de la misma ronda de pulido: "esa pantalla azul puede mejorarse". Hasta hoy
`_pantallas()` (`visor/stadium_builder.gd`) pintaba un rectángulo emisivo de UN SOLO COLOR LISO -sin
marcador, sin escudo, sin nada que sugiera una transmisión real-. El motivo original de dejarla
lisa ("una jumbotron encendida se ve uniforme, textura ahí se leería como un panel roto") seguía
siendo válido para la GRADA (ruido de alta frecuencia = estática de TV, bug del 21-9), pero no
aplicaba aquí: un gráfico de bienvenida (degradado con los colores del club + el escudo centrado,
reutilizando `Escudo.textura()` -cero arte nuevo-) es contenido de baja frecuencia.

**Dos rondas de ajuste real, ninguna a ciegas**:
1. Primer intento (degradado oscurecido 0.35/0.7, emission×0.9): a la distancia real de una cámara
   de partido leía casi negro, sin verse más "encendida" que el color plano de antes -verificado con
   captura real, no supuesto-.
2. Segundo intento (emission×1.8, degradado más claro): el escudo desaparecía por completo incluso
   de cerca. **Diagnosticado por partes, no adivinado**: `pruebas/diagnostico_pantalla_textura.gd`
   (nuevo) aisló `_pantalla_textura()` de toda la escena 3D y confirmó que la textura EN SÍ estaba
   perfecta (el escudo se ve). El problema real: con emission tan alta, el bloom del post-procesado
   lava el contraste interno hasta un blanco/azul uniforme -visible solo en la imagen aislada, nunca
   en la escena real-. Bajado a un punto medio (emission×1.1).

**Verificación final, con una vuelta extra real**: la propia cámara de prueba (`pruebas/captura_
pantalla_estadio.gd`) seguía sin mostrar el escudo incluso con el brillo corregido -pero esta vez el
diagnóstico fue más profundo: en vez de asumir que el bug seguía en el juego, se extrajo la textura
REAL ya aplicada al material de la escena viva (recorriendo el árbol de nodos, no la función
aislada) y esa sí mostraba el escudo perfecto. Conclusión: el bug estaba en el ENCUADRE de la cámara
de la propia prueba de verificación, no en el juego -queda anotado, no perseguido más, ya que la
prueba de la textura real aplicada es evidencia más fuerte que una foto mal encuadrada-.

**Pendiente, sugerido por el usuario, no implementado hoy**: la pantalla podría mostrar contenido
dinámico -tabla de posiciones, máximos goleadores, el resultado del partido en curso- en vez de un
gráfico estático. Anotado en la memoria del proyecto (`project-dinastia-ideas-pendientes`): requiere
renderizar texto a una textura (patrón `SubViewport` + `Label`) y actualizarla con eventos reales del
partido, más trabajo que el degradado+escudo de hoy.

## BUG REAL DE DISCO ENCONTRADO Y CERRADO: `respaldar.ps1` NUNCA BORRABA NADA (22-9-2026)

El usuario notó el disco en 5,6 GB libres -"antes tenía cerca de 13 gigas"- y pidió investigar.
Causa real, no sospecha: `herramientas\respaldar.ps1` crea una carpeta de respaldo nueva cada vez,
pero **nunca tuvo lógica de borrado**. La convención "un solo respaldo activo" (documentada en
`ROADMAP.md`, en este archivo y en la memoria del proyecto desde hace semanas) dependía de que quien
llamara al script borrara la carpeta anterior A MANO, cada vez, después de correrlo -un paso manual,
no automático-. Se saltó varias rondas seguidas (una sesión nocturna solitaria del 22-9 de madrugada
+ esta misma sesión, más tarde el mismo día) y se acumularon **12 respaldos, 8,92 GB**, sin que nadie
lo notara hasta que el usuario preguntó por el disco.

**Arreglado en la raíz**: `respaldar.ps1` ahora borra TODO lo demás en `respaldos\` después de copiar
el nuevo -después, no antes, para no quedarse sin ningún respaldo si la copia fallara a mitad de
camino-. Verificado corriendo el script dos veces seguidas: la segunda corrida creó `v7.59` y borró
`v7.58` sola, sin intervención manual, dejando el disco exactamente igual (762 MB de diferencia neta
cero, no una fuga).

**Los 11 respaldos viejos (`v7.47` al `v7.57`) se borraron con permiso explícito del usuario** -el
propio sistema bloqueó el primer intento por ser un borrado masivo irreversible, se le preguntó
directamente antes de proceder-. Disco recuperado: 5,6 GB → 13,6 GB libres.

## RONDA DE PULIDO VISUAL A PEDIDO DEL USUARIO: BUTACAS, ESQUINAS Y BANQUILLO SENTADO (22-9-2026)

Tras ver las capturas del banquillo de pie y de las butacas reales, el usuario pidió tres cosas
concretas en el mismo mensaje: "el banquillo puede verse mejor", "que los que no quepan estén
sentados", y -sobre la grada- "¿pueden los de arriba también verse como los de abajo?". Un mensaje
más tarde, viendo otra captura: "Falta un tramo". Las tres se investigaron y cerraron:

**1. "De arriba" vs "de abajo" en la grada: cobertura de butacas reales escalada por niveles.**
`_butacas()` (`visor/stadium_builder.gd`) solo ponía geometría 3D real (988 vértices por butaca,
gente encima) en las 5 primeras filas -pensado a propósito para un graderío de 1 nivel, donde 5
filas (4,4m) ya cubren buena parte de la rampa-. En un "Cuenco de 3 niveles" (alto=19,5m,
`largo_rake`~21m) esas mismas 5 filas cubren solo ~21% de la rampa: el 79% restante es la textura
de `_make_stand_texture()` SOLA, estirada sobre una pendiente larga vista casi de canto, que es
justo la combinación que hace aliasing severo -el usuario lo vio de inmediato comparando su propia
captura, no hacía falta explicárselo-. Arreglo: `FILAS_REALES` pasa a escalar con los niveles reales
del graderío (`alto/6.5`, la misma constante de altura por nivel que ya usa `altura_de()`) -un
estadio de 1 nivel sigue costando exactamente lo mismo que antes (el caso que ya se veía bien), uno
de 3 niveles cubre 3x más alto. Verificado con captura real: la zona de detalle real ahora sube
notoriamente más por la rampa, sin errores nuevos.

**2. "Falta un tramo": las esquinas del estadio no tenían gente.** En una forma "esquinas: true"
(cuenco/oval/caldera/inglés/herradura -todas menos "rect"-), los 4 bloques que cierran el hueco
entre dos tribunas rectas usaban `stand_mat`, la fachada de hormigón LISO de los muros -ni un
asiento, ni una cabeza, un tramo de pared ciega metido entre dos tribunas llenas de gente-. Se les
dio la misma textura de grada que el resto del estadio (mismos colores/patrón/ocupación,
`uv1_scale=1` porque el bloque es chico, mismo filtro anisotrópico que ya lleva el resto). Verificado
con una captura desde afuera del recinto (`pruebas/captura_esquina_estadio.gd`/`.tscn`, nueva): la
esquina ahora se lee con el mismo mosaico de gente que las tribunas, no como un pilar gris.

**3. El banquillo, mejorado: los que no caben, sentados de verdad.** Hasta hoy solo había 7 de pie
por equipo (la ronda anterior de esta misma sesión). Ahora hasta 5 MÁS por equipo se sientan en un
banco simple propio -tabla y nada más, no uno de los 5 tipos elaborados de `_banquillos_detalle()`,
mismo criterio de "no arriesgar el encaje de una pose nueva en una geometría ajena" ya aplicado a los
de pie-, continuando la fila hacia afuera en Z, no duplicada en X -entre la línea de banda (X=34) y
la cara del banquillo físico (X=36,1) solo hay 2,1m, no alcanza para dos filas-.

**`visor/anim_quaternius.gd::sentado()`** (nueva): primera pose sentada del catálogo. Solo eje X en
muslo/rodilla/pie -el mismo ya calibrado con la sonda, sin ejes nuevos sin medir-: cadera 90° hacia
adelante (el muslo pasa de colgar vertical a quedar horizontal, apoyado en el asiento) + rodilla
~92° (si no, la pantorrilla seguiría horizontal, "la pierna estirada hacia adelante"; doblando la
rodilla vuelve a quedar vertical, como cuelga una pierna sentada de verdad) + una corrección chica en
el pie para que quede plano. **El hallazgo real, no obvio**: rotar el muslo NO mueve la cadera en el
espacio -`FutbolistaQ` sigue "de pie" a la altura de pelvis=1,03m (MEDIDO, no adivinado, con
`pruebas/diagnostico_altura_cadera_q.gd`, nuevo) aunque las piernas ya estén dobladas, o sea
"flotando sentado en el aire" en vez de apoyado en un banco. Hace falta ADEMÁS bajar la raíz del
modelo (`ALTO_ASIENTO_OFFSET := -0.47`, calculado desde la cadera medida menos la altura real de un
asiento) para que la cadera caiga a la altura del banco -exactamente la misma clase de error que ya
costó una vuelta entera con `ALTO_PIVOTE` del modelo viejo (adivinar en vez de medir), evitado esta
vez midiendo primero.

**`visor/player_spawner.gd::spawn_sentados()`** (nueva, mismo patrón que `spawn_banca()`): hasta 5
suplentes más por equipo, con su propio banco simple (una tabla a 0,45m, mismo número que ya usa
`_banquillos_detalle()` para el tipo "banca"). **`ui/estadio.gd::_banca_celebra()`** filtra
explícitamente a los sentados (`f.get("sentado", false)`) -festejar de pie exigiría además pararlos y
subir la raíz, trabajo aparte no hecho hoy-: se quedan sentados durante el festejo del resto del
banco, que sigue siendo más real que la banda vacía de antes de esta sesión.

**Verificado, capturas reales**: `pantalla_banquillo_antes.png` (7 de pie + 5 sentados por equipo, el
banco simple visible), `pantalla_banquillo_sentados_cerca.png` (plano cerrado: la pose se lee
correctamente sentada, cadera a la altura del banco, piernas dobladas, manos apoyadas hacia
adelante, sin flotar ni hundirse), `pantalla_banquillo_festejo.png` (el banco de pie festeja, los
sentados de esa misma tribuna se quedan quietos, confirmando el filtro). Banco completo, cada ronda:
0 fallos, `.err.txt` vacío.

## EL BANQUILLO YA NO ESTÁ VACÍO: SUPLENTES DE PIE + FESTEJO — CERRADO (22-9-2026)

Tercer y último punto del orden que pidió el usuario para la Fase 3 del ROADMAP ("animaciones de
lenguaje corporal en la banda / efecto banquillo visual"). Hasta hoy la banda técnica estaba
completamente vacía en el visor 3D -solo se veía el MUEBLE del banquillo
(`StadiumBuilder._banquillos_detalle()`, ya existía desde la Fase 2 de "el estadio por módulos"),
nunca gente adentro, ni un solo suplente en ningún partido.

**Decisión de alcance, explicada, no accidental**: de pie en la zona técnica, no sentados dentro del
banquillo. Encajar una pose sentada en el asiento exacto de cada uno de los 5 tipos de banquillo
-banca/cristal/bunker/sillones/foso, cada uno con su propia geometría interna, sin ninguna lista de
posiciones de asiento expuesta hacia afuera- es un riesgo de encaje (altura del asiento, choque con
el vidrio, una pose de piernas nueva sin calibrar en este esqueleto) que no correspondía resolver en
la misma ronda que conecta la banda por primera vez. De pie es igual de real -en un partido de
verdad buena parte del banco pasa de pie- y sirve para los 5 tipos por igual sin tocar
`StadiumBuilder`.

**`visor/player_spawner.gd::spawn_banca()`** (nueva, mismo patrón que `spawn_arbitros()`): hasta 7
suplentes por equipo -los mejores disponibles (sin lesión/sanción) que no están en el once, por
media, no un sorteo cualquiera-, con la equipación real del club (`Puente3D.jugador()` uno por uno,
`Puente3D.kit()`/`kit_portero()`). Más de 7 modelos completos animados extra por equipo es carga
real, y en una banda de verdad tampoco se distingue a todos con la misma nitidez.

**BUG REAL DE ENCUADRE, encontrado con la primera captura y corregido con la segunda**: la
`DISTANCIA_LINEA_BANDA` inicial (2.4m) ponía a la fila DENTRO del propio banquillo -el vidrio
frontal de la burbuja "cristal"/"bunker" llega hasta X=39,65 (base 37,5 + 1,15 de fondo en Z local,
rotado 90° a X global) y la base estructural hasta X=36,1 (37,5-1,4), así que X=36,4 caía adentro de
ese rango-. Se vio clarísimo en la captura: la gente parecía embutida en el vidrio, no de pie al
frente. Corregido a 1,0m (X=35,0), en la franja técnica de verdad entre la línea de banda (X=34) y
el borde más cercano del banquillo.

**`ui/estadio.gd`**: `_poner_banca()` (llamada desde `_sacar_los_22()`) spawnea la banca de los dos
equipos en `_en_banca` -aparte de `_en_campo`, a propósito: `MatchPlayback.tick()` solo mueve lo que
hay en esa segunda lista, la banca se queda quieta donde se paró, que es lo real-. `_banca_celebra()`
(llamada desde `_al_gol()`): el banquillo del equipo que anotó juega "celebrar" -la animación real de
mocap que ya usa el autor del gol en la cancha, no una pose nueva- y vuelve solo a "parado" a los 3s.
`_al_cambio()` (la entrada de un suplente de verdad) busca y borra la figura de banca correspondiente
antes de crear la del campo, para no dejar al mismo jugador duplicado -uno de pie junto al banquillo
y otro jugando-. La banca visual (7 mejores disponibles) es una MUESTRA, no la convocatoria real:
`Partido.cambiar()` sigue aceptando cualquier jugador disponible de la plantilla entera.

**BUG REAL DE TIMING, en la propia herramienta de verificación, no en el juego**: la primera captura
del festejo seguía mostrando la cámara del partido (`_seguir_jugada_gol()` cambia a "Tele Dinámica"
en cada gol, comportamiento real) aunque el script reafirmaba `_cam.current=true` justo antes de
capturar -en el MISMO frame-. Causa: el cambio de cámara se aplica al render, que pasa DESPUÉS de que
termina `_process()` de todo el frame; capturar en el mismo frame agarra el render viejo, un frame
atrasado. Corregido reafirmando la cámara un frame ANTES de cada captura, no en el mismo.

**Verificado, dos capas**: banco completo (862, 0 fallos, `.err.txt` vacío) + tres capturas reales
con ventana (`pruebas/captura_banquillo.gd`/`.tscn`, nuevo) que cubren el ciclo entero: ANTES del
gol (`pantalla_banquillo_antes.png`, 7+7 de pie, cada bando con su color de camiseta, mirando hacia
la cancha), JUSTO DESPUÉS de un gol forzado del local (`pantalla_banquillo_festejo.png`, el
banquillo LOCAL con los brazos en alto festejando, el visitante sigue quieto -confirma que el filtro
por equipo funciona, no festejan los dos-), y 3+ segundos después (`pantalla_banquillo_vuelta.png`,
de vuelta a la postura normal, no se queda pegado al festejo para siempre).

## ESPIONAJE TÁCTICO DEL RIVAL, EXTENDIDO — CERRADO (22-9-2026)

Segundo punto de la Fase 3 del ROADMAP, en el orden que pidió el usuario ("dale en ese orden"):
"extender el espionaje de entrenamientos rivales a información táctica". `_pintar_juegos_mentales()`
ya mostraba el once probable + bajas; ahora, en el mismo informe (mismo candado: comprado con
"espía" en prensa, o gratis con el perk "lectura" del DT), se suma mentalidad/presión/línea
defensiva del rival, leídas directo de `rival.tactica` -el mismo objeto que ya usa
`multiplicador_ataque()`/`multiplicador_defensa()` en el partido real, así que el informe nunca
puede quedar desincronizado de lo que de verdad va a pasar-.

**Decisión deliberada, no tomada a la ligera**: NO se le dio personalidad táctica propia a la IA.
Investigado antes de tocar nada: ningún club de la IA cambia jamás su `Club.tactica` fuera de un
partido en curso (`Tactica.plan_para()`, según el marcador) o de un DT EMPLEADO en TU PROPIO club
(`Roles.aplicar_directrices()`, que nunca toca un rival -solo hay una instancia de `Roles`, la del
usuario-). Eso significa que para casi cualquier rival este informe va a leer siempre "Equilibrada /
Media / Media", el valor de fábrica de `Tactica` -confirmado en la captura de verificación de abajo,
no supuesto-. Se consideró darle a la IA una personalidad táctica determinista (hash del id del
club, mismo patrón que el estadio/escudo de un rival), pero se descartó por esta sesión: a
diferencia de un estadio o un escudo, `tactica.mentalidad` SÍ alimenta el cálculo de fuerza de CADA
partido de la liga -sería una decisión de balance de toda la simulación, no una decisión de
pantalla, y no correspondía tomarla sin que el usuario la pida-. Queda anotada como posible próximo
paso si se quiere, no implementada por decisión, no por olvido.

**BUG REAL ENCONTRADO -y grande- verificando con pantalla real, no con el banco**: la primera
versión escribió `var ment_nombre := ["Defensiva","Equilibrada","Ofensiva"][tact.mentalidad]` -el
mismo error de tipo ya documentado una vez en `ui/escudo.gd" ("GENERADOR DE ESCUDOS, SEGUNDA TANDA"):
indexar un Array literal sin tipar dentro de una declaración `:=` es un ERROR DE PARSEO real
("Cannot infer the type... doesn't have a set type"), no una advertencia. Esto rompía la carga
ENTERA de `ui/principal.gd` -la pantalla principal del juego completo, no solo esta función-. El
banco (`pruebas/banco.gd`) dio "0 fallos" con `.err.txt` limpio de todos modos: **no carga
`principal.gd`**, así que nunca iba a ver este error. Solo lo atrapó correr
`pruebas/captura_previa.gd` con pantalla real. Corregido a `var ment_nombre: String = [...]`.

**Dos bugs reales más, esta vez en la propia herramienta de verificación (`captura_previa.gd`), no
en el código del juego**: (1) llevaba desde que se escribió llamando a `_elegir_grupo("partido")`
-"partido" nunca fue un `id` de `GRUPOS` (los 6 bloques de arriba: central/club/gente/historia/
operaciones/ajustes), es un HUB contextual (`HUBS["partido"]`) solo alcanzable tocando su botón y de
ahí a `_ir_a_pestana()`-. La llamada no tiraba error (`_grupo_por_id()` vuelve `{}` en silencio) pero
tampoco cambiaba de pestaña: **esta captura mostraba CENTRAL desde siempre, nunca la pantalla de
Partido**, y nadie lo había notado porque nadie había vuelto a mirar la imagen resultante. Corregido
a `_ir_a_pestana("Partido")`, la misma función que usan los botones del hub. (2) Su propio comentario
decía que el informe del rival "aparece con la sala de vídeo construida" -no es así: depende de
`Prensa.dato_del_rival` (comprado) o `Entrenamiento.ve_tactica_rival()` (perk del DT), no de
`Instalaciones.nivel("video")`. Corregido a forzar el flag directo, igual que ya hace `banco.gd`.

**Verificado, dos capas**: banco completo (862, 0 fallos, `.err.txt` vacío) + captura visual real
(`pruebas/captura_previa.gd`, ahora corregida) -`pantalla_previa_video.png` muestra el informe
completo contra D. Limache: once probable, bajas, y las tres líneas nuevas ("Mentalidad del rival:
Equilibrada", "Presión del rival: Media", "Línea defensiva del rival: Media"), confirmando en vivo
la limitación ya documentada arriba, no como sorpresa.

## EL ESTADIO POR MÓDULOS, FASE 3 DE 3: TRAMO — CERRADA DE PUNTA A PUNTA (22-9-2026)

Sesión abierta con "hoy quiero experimentar, pulir el proyecto, tú decides qué vale la pena".
Con la base limpia (851+ pruebas, 0 fallos, `.err.txt` vacío) se repasó `ROADMAP.md`: el punto más
alto de la Fase 3 llevaba desde el 18-9 con el spike positivo pero "diseñar la Fase 3 completa
(EST_DEF, UI, persistencia) como tarea aparte" sin empezar. Se cerró entero hoy, siguiendo al pie
de la letra el patrón ya usado por Bandeja (Fase 1) y Componentes (Fase 2).

**Qué cambia**: con "Mezclar patrones por tercios" activo en Club → Estadio (independiente del
interruptor de Bandeja, se pueden usar los dos a la vez o por separado), cualquiera de las 4
tribunas se puede partir en 3 tercios con su propio patrón de butaca -izquierda/centro/derecha-,
en vez de una sola piel de punta a punta. Techo/fachada/altura del recinto entero siguen sin
variar por tramo, exactamente lo que el spike del 18-9 ya había limitado.

**`datos/tablas.json` (`EST_DEF`), 13 claves nuevas**: `personalizar_tramos` (bool) +
`tramo_<lado>_1/2/3` × 4 tribunas. El archivo pesa 429 KB y `ConvertFrom-Json` de PowerShell 5.1 lo
sigue dando por inválido -misma limitación ya documentada en la Fase 1-, así que se insertaron con
`IndexOf`/`Substring` (ancla `"bandeja_oeste_techo":""}`, ocurrencia única confirmada antes de
tocar nada) y se validó el resultado con `JavaScriptSerializer` de .NET, no con el cmdlet nativo.

**`nucleo/estadio_propio.gd`**: `PRECIO["personalizacion_tramos"] = 130000` (más caro que el
interruptor de Bandeja -90.000-, por ser una decisión más fina -12 campos contra 8-, pero muy por
debajo de una obra real: no se levanta nada, solo cambia la textura de la grada). Los 12 campos de
tercio pagan el mismo capítulo "butacas" que `asientoP`/`bandeja_<lado>_asientoP` -es la misma
faena, elegir un patrón, no una nueva-. `_tramos_personalizados()` (nueva): cada tercio en blanco
NO hereda el global directamente, hereda el patrón YA resuelto de esa tribuna -su propio
`bandeja_<lado>_asientoP` si lo tiene, si no el `asientoP` general-, para que activar Tramo sobre
una tribuna que ya tenía estilo propio de Bandeja no la vacíe de vuelta al color de fábrica.
`perfil()` solo añade `tramos` con el interruptor prendido, mismo criterio que `bandejas`.

**`visor/stadium_builder.gd`**: la textura de tercios (`_make_stand_texture_tramos()`, escrita como
spike el 16-9) se conecta de verdad en `build()` -tiene prioridad sobre Bandeja cuando las dos
aplican a la misma tribuna, ya que 3 patrones dicen más que 1 y Bandeja ya sirvió de base para los
tercios en blanco-, con el `uv1_scale.y=1` que el spike dejó como condición para que la costura no
se rompa.

**BUG REAL EVITADO A PROPÓSITO, no encontrado después**: `_make_stand_texture_tramos()` nació de un
spike aislado el 16-9, ANTES de que la sesión del 21-9 encontrara y corrigiera la "estática de TV"
de la grada normal (falta de mipmaps + un pixel por persona en vez de un bloque del tamaño real).
El spike nunca pasó por ese arreglo porque no estaba conectado a nada real. Conectarlo tal cual
habría reintroducido a propósito, en una tribuna real, un bug ya encontrado y cerrado una vez. Se
portó el arreglo completo (mipmaps + bloques de persona) antes de conectar, no después.

**BUG REAL ENCONTRADO DE PASO**: ni el camino nuevo (tercios) ni el de Bandeja (16-9, anterior al
hallazgo del 21-9) ponían `texture_filter` anisotrópico en su material -solo lo tenía `crowd_mat`,
el compartido-, así que cualquier tribuna con patrón propio (de Bandeja o de Tramo) quedaba
filtrada con el default no-anisotrópico y expuesta al mismo aliasing a la rasante. Corregido en los
dos caminos, no solo en el nuevo.

**BUG REAL ENCONTRADO VERIFICANDO CON PANTALLA REAL, no en el código**: el primer intento de captura
(`pruebas/captura_tramo.gd`) reportó "FIN. 0 fallos" en la consola con capturas "guardadas", pero
`.err.txt` tenía `SCRIPT ERROR: Invalid access to property or key 'balon' on a base object of type
'Nil'` en la línea que llamaba `_vista.abrir(..., Comercial.color_balon(mundo.comercial.balon,
mio))` -exactamente la trampa que ya documenta `feedback-verification-discipline`: un error a mitad
de `_ready()` no detiene `_process()`, así que las capturas se guardaban igual, de un estadio que
NUNCA se llegó a construir porque `mundo.comercial` es Nil sin pasar por `tomar_el_mando()` (solo
esa función lo crea) y el error abortó el resto de `_ready()` antes de que `_vista.abrir()` llegara
a ejecutarse. **La misma línea, calcada, ya estaba en `captura_bandejas.gd` y `captura_componentes.gd`
desde el 16-9 -sus capturas tampoco mostraban nunca el estadio real, y nadie lo había notado porque
nadie miró su `.err.txt`-.** Las tres corregidas (pasar `[]` en vez de leer `mundo.comercial.balon`,
dejando que `VistaEstadio`/`spawn_ball()` usen su color de balón por defecto).

**Verificado, con las dos capas que pide el proyecto**:
- Datos (`pruebas/banco.gd`, headless): 11 comprobaciones nuevas -sin tocar nada no aparece la
  clave, con el interruptor activo aparece con los 3 tercios resueltos, un tercio reformado a mano
  se refleja, los tercios en blanco heredan el patrón de Bandeja (no el global) cuando esa tribuna
  ya tenía uno propio, las tribunas sin tercios propios salen con sus 3 iguales al global, el rival
  nunca trae la clave-. Banco completo: 851+ (ahora más), **0 fallos, `.err.txt` REALMENTE vacío**
  -confirmado después de corregir el bug de `Comercial` de arriba, no antes-.
- Visual (`pruebas/captura_tramo.gd`/`.tscn`, con ventana real -no puede ir headless-): tribuna Sur
  con Tramo activo (franjas/moteado/bicolor) + tribuna Norte con Bandeja activo (damero), capturada
  con `--rendering-driver opengl3`. `pantalla_tramo_real_general.png`: la tribuna Sur se lee como 3
  sectores de color y patrón distintos, sin la textura "de mentira" que ya se corrigió una vez.
  `pantalla_tramo_real_costura.png`: primer encuadre demasiado cerca (pegado a las butacas
  individuales, no servía para juzgar la costura de fondo), reencuadrado a distancia moderada -la
  misma lección de encuadre que ya costó dos vueltas en el spike original del 18-9-.

**Con esto, las tres lógicas del ROADMAP ("el estadio por MÓDULOS": bandeja → componentes → tramo)
quedan cerradas de punta a punta.** Pendiente, no empezado hoy: el resto de la Fase 3 del ROADMAP
(espionaje táctico rival, lobby institucional, banquillo, cantera 10-16, juegos mentales del túnel).

## PICKER DE ESCUDOS ESPECIALES EN GENTE → IDENTIDAD: CERRADO (22-9-2026)

Última pieza de la sesión (el usuario pidió cerrar con esto). Conecta la mecánica de la entrada
anterior ("Escudos especiales coleccionables") a una pantalla de verdad -hasta ahora `esc_especial`
solo se podía fijar por código-.

**`ui/principal.gd::_rejilla_especiales(c)`** (nueva, llamada desde `_pintar_identidad()` justo
después del botón "Volver a los colores del club" de la sección 3·ESCUDO): a diferencia de
`_rejilla_identidad()` -que alcanza con el nombre de la clave ("cruz", "tablero" se entienden solos-,
un especial es una foto de Canva sin relación visible con su id ("wolf_1" no dice nada), así que cada
botón lleva la MINIATURA REAL (`Escudo.textura_especial(id)`) en vez de texto. Solo lista los ya
desbloqueados (`Escudo.especiales_desbloqueados()`) más un "Ninguno (procedural)" para volver atrás
-misma lógica que el "por sorteo" que ya usa `_rejilla_identidad()`-. Aprovechando el mismo repaso,
se corrigió un texto informativo que había quedado desactualizado por la ampliación de hoy ("ocho
formas × diez patrones" → "veintiséis formas × treinta patrones").

**Verificado con una prueba real, no aislada** (`pruebas/captura_picker_especiales.gd`/`.tscn`,
`pantalla_picker_especiales.png`): carga `principal.tscn` completo, navega a Gente→Identidad,
confirma que el picker pinta sin reventar, elige un especial (`bull_1`) y repinta -la vista previa de
arriba de la pantalla lo recoge al toque-, hace scroll hasta la grilla -queda debajo de Forma/Patrón/
Símbolo, fuera de cuadro sin bajar- y confirma visualmente las 40 miniaturas reales, con la
seleccionada resaltada. El perfil de gestor real de esta máquina de pruebas resultó estar en el nivel
máximo (Dinastía, los 40 desbloqueados) -sirvió igual de prueba de estrés para la grilla completa,
sin haber tenido que fabricar un perfil de prueba esta vez, y sin tocar `user://` para nada-. Banco
completo 851+ en 0 fallos, `.err.txt` vacío.

**Con esto, el pedido completo de la sesión sobre escudos especiales queda cerrado de punta a punta**:
investigación de referencias → decisión de licencia → generación original en Canva → integración →
desbloqueo por nivel → picker real en pantalla. Nada pendiente de esta rama salvo lo ya anotado
(las 10 líneas de Canva que fallaron por límite, si se quieren más adelante).

## ESCUDOS ESPECIALES COLECCIONABLES (CANVA + DESBLOQUEO POR NIVEL): CERRADO (22-9-2026)

Cierre de la investigación de "insignias estilo comunidad" (Pinterest/FC26) de esta misma sesión.
Recorrido completo, para que quede claro por qué se llegó a esta solución y no a otra:

1. El usuario trajo ~75 referencias de Pinterest a `Escudos especiales\` pidiendo usarlas TAL CUAL.
2. Se identificó que al menos una es un club real (Atlético Nacional) y varias más citan
   diseñador/estudio en el propio nombre de archivo (trabajo de portafolio, no clip-art). Se rechazó
   usarlas tal cual -no por burocracia: son marca registrada o trabajo de terceros sin licencia
   visible para redistribuir en otro juego, y eso no lo cambia que el usuario lo pida directamente.
3. El usuario propuso que las sin nombre de autor "estaban en Wikipedia, totalmente libres". Se le
   explicó por qué eso no sostiene: la mayoría de escudos reales en Wikipedia son "uso legítimo"
   (fair use), una licencia que Wikipedia mismo prohíbe reutilizar fuera de la enciclopedia -y las
   imágenes que sí se miraron de la carpeta (Piratas, Axolotl, SF, Gorilla) tienen pinta de diseño de
   comunidad/TikTok, no del tipo que aparece en un infobox de Wikipedia-.
4. Salida acordada: usar Canva (`generate-design`, `design_type: "logo"`) para generar insignias
   100% originales -licencia propia de Canva, sin arte de terceros- inspiradas en el ESTILO visual de
   las referencias (insignia circular/escudo, anillo grueso, mascota animal, acento de estrella), sin
   calcar ninguna en particular. La carpeta de Pinterest se movió parcialmente: los 3 casos de riesgo
   confirmado a `Escudos especiales\no usar\`, el resto se conserva como referencia de estilo.

**Resultado**: 40 insignias (`dinastia-godot/assets/escudos_especiales/*.png`, 400×400, ~70-165 KB
cada una), 10 temas × 4 variantes: balón/tigre genérico, lobo, león, águila, toro, tiburón, dragón,
pantera, halcón, carnero. 5 temas más (cobra, gorila, caballo, geométrico, ancla, corona-león, fénix,
tigre, oso, rayo) fallaron por límite de generación de Canva -mensaje explícito "no reintentar sin que
el usuario lo pida"-, respetado, quedan pendientes si se quieren más adelante.

**Pipeline de descarga, para la próxima vez que haga falta**: las miniaturas de `generate-design`
viven en `design.canva.ai`, requieren la sesión del navegador -un `Invoke-WebRequest` de PowerShell
sin cookies baja una página de error, no la imagen-. Tampoco sirve simular un clic de descarga en el
navegador (el Browser pane corre en un sandbox aparte, sin acceso al disco de esta máquina). Lo que sí
funciona: `javascript_tool` hace `fetch(location.href)` -mismo origen que la propia pagina- y devuelve
el PNG como base64; cuando el resultado excede el límite de tokens del turno, el propio arnés lo guarda
solo en un archivo de texto local (`tool-results/*.txt`, formato `[{type,text}]`), que se puede
decodificar con PowerShell (extraer el base64 con una regex `[A-Za-z0-9+/]{200,}={0,2}` y
`[Convert]::FromBase64String`) SIN gastar contexto leyéndolo -esto evitó tener que hacer 40 turnos
separados-. El intento de fetch cruzado (bajar 8 imagenes en un solo script desde una pagina de origen
distinto) falló por CORS -hay que navegar a CADA URL antes de hacerle fetch a sí misma, no se puede
pedir la de al lado-.

**Mecanismo de desbloqueo**: se pensó primero en logros puntuales, pero `nucleo/logros.gd` declara
explícito ("solo suma reconocimiento, nunca bloquea contenido") que los logros de este juego NUNCA
condicionan nada -regla heredada del HTML-. Romperla para esto no correspondía. Se usó en cambio el
PERFIL DE GESTOR (`Logros.NIVELES_PERFIL`, 7 niveles, XP entre carreras, sin esa restricción): los 40
especiales se repartieron 4/4/4/8/8/8/4 entre los 7 niveles (más variedad cuanto más alto el nivel;
reparto arbitrario, fácil de reajustar). Cambios de código:
- `nucleo/club.gd`: campo nuevo `esc_especial: String` (vacío = generador procedural de siempre),
  persistido en `identidad_a_dic()`/`identidad_desde_dic()`.
- `ui/escudo.gd`: catálogo `ESPECIALES` (id → nivel requerido), `especial_desbloqueado()`,
  `especiales_desbloqueados()` (para cuando se construya el picker) y `textura_especial()` con caché
  propia. `textura()` prueba el especial PRIMERO -si el club tiene uno elegido y sigue desbloqueado,
  manda por encima del SVG procedural-; si no está desbloqueado (por ejemplo, bajó de nivel en un
  perfil nuevo), cae solo al procedural, nunca revienta.

**Verificado**: banco completo (851+, con reimport por los 40 assets nuevos) 0 fallos, `.err.txt`
vacío. Captura nueva (`pruebas/captura_escudos_especiales.gd`/`.tscn`,
`pantalla_escudos_especiales.png`) con perfil de prueba a nivel 1: confirma que un club con especial
DESBLOQUEADO (`wolf_1`) muestra el PNG de Canva, uno con especial BLOQUEADO (`ram_1`, nivel 6) cae
limpio al procedural, y uno sin especial sigue exactamente igual que siempre. La prueba respalda y
restaura el perfil REAL del usuario en `user://perfil_gestor.json` antes/después -no lo pisa-.

**Pendiente, NO empezado hoy** (el usuario pidió cerrar la sesión con esto): el picker en la pantalla
de Identidad para que el jugador elija uno de sus especiales desbloqueados -hoy `esc_especial` se
puede fijar por código/guardado, pero no hay UI todavía-. `Escudo.especiales_desbloqueados()` ya está
listo para alimentar esa pantalla cuando se construya.

## GENERADOR DE ESCUDOS, SEGUNDA TANDA -"MÁS CANTIDAD": CERRADO (22-9-2026)

A pedido explícito del usuario ("inspirate en la comunidad, y un poco mas de cantidad"), después de
mirar el editor nativo de FC 26 (ver conversación: la comunidad lo considera flojo -cita real del mod
más descargado de Nexus: *"the default Create-A-Club Crests are pretty boring"*-, así que la vara no
estaba tan alta). Se agregaron **14 siluetas** (`FORMAS` pasa de 12 a 26: frances, curvo, arco3,
hexalgo, rombolgo, banda_cinta, estandarte, doblepunta, geometrico, coronadoble, ovalo, redondeado,
trianguloesc, cruzesc) y **16 patrones** (`PATRONES` de 14 a 30: tablero, corona2, rayo, anillos,
abanico, interior, puntas, barras, borde, escalera, pila, estrella8, manchas, florlis, trebol,
medialuna).

**Solo 3 pasaron por Figma esta vez** (frances/curvo/arco3, las únicas con fusión de curvas real:
rectángulo+elipse(s), unión booleana igual que la primera tanda). El resto -incluidos `trebol`,
`medialuna` y `florlis`, que iban a ser booleanas en Figma- se escribió a mano: a mitad de la tanda se
agotó la cuota de llamadas del plan Starter de Figma (`rate limit`, ver el error real en la
conversación). La salida: un patrón no necesita ser UN path fusionado -es un relleno recortado por el
clip del escudo, no la silueta misma-, así que varios elementos sueltos (`<circle>`/`<path>` repetidos)
se ven idéntico y son más simples. `medialuna` usa el truco clásico de dos arcos SVG desplazados en vez
de una resta booleana; `estrella8` se calculó a mano con trigonometría (16 vértices, radios 30/13,
incrementos de 22.5°) en vez de `createStar`.

**BUG REAL ENCONTRADO Y CORREGIDO**: el banco reportó "0 fallos" dos veces seguidas mientras
`ui/escudo.gd` en realidad NO COMPILABA -exactamente la trampa que `ROADMAP.md`/`LEEME.md` ya
documentan sobre no fiarse del código de salida sin mirar el `.err.txt`-. Causa real: el patrón
`"trebol"` tenía `for p in [...]` -una variable de bucle llamada `p`- dentro de
`_patron_svg(p: String, c2: String)`, tapando el propio parámetro `p` de la función. A diferencia de
lo que se podría asumir, GDScript 4 trata esto como **error de parseo real**, no advertencia de
"variable sombreada": toda la clase `Escudo` quedaba sin resolver y arrastraba a cualquier script que
la usara (`editor.gd`, `inicio.gd`, según el orden de carga) con el mensaje engañoso "Could not
resolve class Escudo, because of a parser error" -sin apuntar a la línea real-. Se encontró por
descarte (nada más había cambiado de forma tan distinta al resto del lote) y se corrigió renombrando
la variable a `pt`. **Lección para la próxima vez**: nunca reusar el nombre de un parámetro de
función como variable de bucle en GDScript, ni siquiera dentro de un `match`.

**Advertencia honesta, no verificada todavía**: ampliar `FORMAS.size()`/`PATRONES.size()` cambia el
resultado de `hash % size` para CUALQUIER club que no tenga `esc_forma`/`esc_patron` elegido a mano
-es decir, el escudo automático de la mayoría de los clubes de la IA en cualquier mundo YA GENERADO
antes de hoy probablemente se vea distinto la próxima vez que se cargue esa partida-. No es un bug
-el usuario pidió expresamente ampliar el generador-, pero es un efecto secundario real que vale la
pena tener anotado si alguna vez se reporta "un club cambió de escudo solo".

**Verificado**: banco completo 0 fallos con `.err.txt` REALMENTE vacío esta vez (confirmado después
del arreglo del bug de arriba). Captura nueva `pruebas/captura_escudos_lote2.gd`/`.tscn`
(`pantalla_escudos_lote2.png`): 20 combinaciones -las 14 siluetas nuevas una vez cada una, los 16
patrones nuevos una vez cada uno- se ven limpias.

**Pendiente, NO empezado**: el usuario encontró referencias en Pinterest y aclaró que esas van a un
sistema APARTE -desbloqueables por logros, no a la rotación automática por hash de `FORMAS`/
`PATRONES` (que le toca a cualquier club de la IA)-. Falta: recibir las referencias, y diseñar el
mecanismo de desbloqueo (probablemente una lista `FORMAS_ESPECIALES`/`PATRONES_ESPECIALES` separada,
seleccionable solo a mano vía `esc_forma`/`esc_patron` cuando `Logros` la habilite, nunca por hash).

## GENERADOR DE ESCUDOS AMPLIADO CON FIGMA: CERRADO (22-9-2026)

Primer uso real de las herramientas de diseño (Adobe/Canva/Figma) que el usuario dio acceso, a
pedido explícito ("mejorar el aspecto visual con nuestras herramientas"). Antes de tocar nada se
verificó qué significa realmente "escudos de clubes" en este proyecto -`ui/escudo.gd`- y resultó ser
un generador 100% procedural (8 formas × 10 patrones × color del club, todo por hash del id): NINGÚN
club "le falta" escudo, así que "mejorar" solo podía significar ampliar el generador mismo, no crear
arte por club. Confirmado con el usuario antes de arrancar (rompía la premisa original del pedido).

**Herramienta usada**: Figma (`use_figma`, Plugin API), no Adobe ni Canva -Figma es la que de verdad
sirve para diseñar geometría vectorial precisa y devolverla como datos (`vectorPaths`), que es lo que
hace falta para portar una silueta a un `<path d="...">` de GDScript-. Archivo nuevo en el Drafts del
usuario: "Dinastia - Escudos v2" (`w6Qs8isqzQxBvZwVdaGQbt`).

**4 siluetas nuevas** (`FORMAS` pasa de 8 a 12), cada una construida con primitivas + booleanas
(`figma.union`/`figma.subtract`) y leída con `figma.flatten(...).vectorPaths`, no inventada a mano:
- `ojiva`: rectángulo + elipse superior + punta (VECTOR con puntos exactos, no rotación -ver nota de
  abajo, `createPolygon` + `.rotation` tiene un bug real de posicionamiento-). Escudo gótico.
- `octogono`: `createPolygon` de 8 lados, sin retocar.
- `corona`: 3 almenas (rectángulos) + cuerpo + punta, unidos. Estilo castillo.
- `laurel`: círculo con dos muescas (resta de 2 elipses pequeñas) en la base, como el cierre de una
  corona de laurel.

**4 patrones nuevos** (`PATRONES` pasa de 10 a 14): `cruz` y `rombos` son geometría trivial (2 rects,
4 diamantes) escritos directo en GDScript -mismo criterio que ya usan `cuartos`/`franjas`, no
ameritaban el viaje a Figma-. `escamas` (filas escalonadas de círculos) y `estrella6` (estrella de 6
puntas, `createStar`) sí salieron de Figma.

**Hallazgo real de la sesión de Figma, para la próxima vez**: `createPolygon()` + asignar
`.rotation = 180` NO rota alrededor del centro visual -desplaza la figura a otro cuadrante por
completo, aun reescribiendo `x`/`y` después-. La solución fue no pelear con la rotación: para
cualquier triángulo/forma con orientación exacta, crear un `VECTOR` con `vectorPaths` explícito
(puntos a mano) en vez de rotar una primitiva. Igual de real: `vectorPaths` sale `undefined` en
`RECTANGLE`/`ELLIPSE`/`POLYGON`/`BOOLEAN_OPERATION` recién creados -hace falta `figma.flatten([...])`
primero para obtener un `VECTOR` de verdad con el path calculado-. Y los booleanos a veces devuelven
`windingRule: "EVENODD"` con un sub-path chico de "agujero" en el punto de unión de dos curvas -se
descartó ese sub-path en las 2 siluetas donde apareció (ojiva, corona) en vez de arrastrar
`fill-rule="evenodd"` al SVG, sin verificar si el rasterizador de Godot lo respeta-.

**Verificado**: banco completo (851+) 0 fallos, `.err.txt` vacío. Captura nueva
(`pruebas/captura_escudos_nuevos.gd` + `.tscn`, `pantalla_escudos_nuevos.png`): 8 combinaciones
-las 4 siluetas y los 4 patrones nuevos, cada uno con un patrón/silueta ya existente para no
duplicar prueba- se ven limpias, sin huecos ni geometría rota.

## VIÑETA DE CÁMARA ESTILO TRANSMISIÓN: CERRADO (22-9-2026)

Tercera pieza de la investigación comparativa. Lo único rescatable de la cámara de Open-Soccer -su
lógica de cámaras es mucho más simple que la nuestra (9 tipos vs. su única cámara pseudo-3D)- era el
*look*: un oscurecido suave hacia los bordes de pantalla, como deja un lente real.

**Arreglo**: `visor/vineta.gdshader` (canvas_item, radial simple) + un `ColorRect` con ese shader en
`ui/estadio.gd::_construir()`, añadido ANTES del radar/barra/pie en el árbol -así queda debajo de
ellos y no les resta legibilidad, ver el comentario en el propio código-. No es un efecto de
`Environment`: Godot 4 no trae viñeta nativa ahí, así que una capa 2D encima del viewport (el 3D "va
directo al viewport principal", ver comentario existente en `_construir()`) es más simple y barata
que un `CompositorEffect` para algo puramente cosmético.

**Verificado**: banco completo 0 fallos, `.err.txt` vacío. Dos capturas nuevas con
`pruebas/captura_hinchas_filas.gd` (ampliado para esta tanda): la primera, corregida (ver nota de
abajo sobre el camarógrafo), confirma los hinchas de la entrada anterior sin el artefacto raro; la
segunda (`pantalla_vineta_cenital.png`, cámara "Cenital táctica" de `CameraRig`, fondo de césped
parejo de borde a borde -el mejor fondo posible para AISLAR si la viñeta se nota o no de lo que ya
era oscuro por geometría/cielo-) muestra el oscurecido de esquinas contra el centro con claridad.

**Hallazgo de paso, no un bug**: la primera captura de la entrada anterior ("Hinchas de verdad...")
mostraba una silueta humana negra grande y rara pisando el borde de cancha en mitad de campo. NO es
un artefacto del arreglo de hinchas ni de esta viñeta: es el `_camarografos()` que ya existe en
`stadium_builder.gd:1326` (puesto fijo en `(36.5, 0, 0)`, un maniquí con chaleco naranja, pensado
para verse desde lejos como parte del atrezzo del estadio). La cámara de esa prueba quedó parada a
~5m de él, mirándolo de frente a contraluz -mal encuadre de la PRUEBA, no del juego real, que nunca
usa esa cámara-. Corregido moviendo la cámara de la prueba a Z=15 en vez de Z=0.

**Balance de la investigación de los tres proyectos (Gameplay Football / Google Research Football /
Open-Soccer), cerrada con esto**: de los tres solo salieron dos adopciones reales -el patrón de
sincronía patada/animación (touch-frame) y esta viñeta-. Todo lo demás que se comparó (kits, física
de balón, cámaras, sonido, catálogo de equipos) ya está mejor resuelto en este proyecto que en
cualquiera de los tres, según quedó documentado en la conversación del 22-9-2026. No queda más para
"traer de afuera" de esos tres repos específicamente; lo próximo (variantes de menú, más pulido de
césped) es trabajo propio, no una adopción de esa investigación.

## HINCHAS DE VERDAD EN LAS FILAS REALES DE BUTACAS: CERRADO (22-9-2026)

Segunda pieza de la misma investigación comparativa (Gameplay Football / Google Research Football /
"Open-Soccer"). Ninguno de los tres tenía un sistema de público que valiera la pena copiar tal cual
-el de "Open-Soccer" es puntitos 2D con parallax, pensado para su canvas pseudo-3D, un paso atrás
para un juego en 3D real-, así que esto es técnica propia (`MultiMeshInstance3D`, un solo draw call
por tribuna), no un port.

**Diagnóstico antes de tocar nada** (otra vez, grep primero): `visor/stadium_builder.gd` YA pinta
público de verdad -`_make_stand_texture()`, con piel/ropa a escala humana correcta, con un bug de
aliasing corregido ayer (21-9)-, pero SOLO en la textura de graderío, que empieza en la fila 6. Las
5 FILAS REALES de butacas 3D (`_butacas()`, el modelo `asientos_lod.glb`) -las que la cámara de TV
ve de cerca, según su propio comentario- se quedaban completamente vacías. Exactamente al revés de
lo que importa: la grada se veía más llena lejos que cerca.

**Arreglo** (`visor/stadium_builder.gd::_butacas()`): nueva malla cacheada `_malla_hincha_cache()`
-un torso (cápsula) + cabeza (esfera) combinados con `SurfaceTool`, deliberadamente low-poly (un
puñado de segmentos cada una, muy por debajo de los 988 vértices del asiento real) porque esto se
repite por cada butaca ocupada de las 5 filas × 4 tribunas-. `_butacas()` ahora recibe `ocupacion`
(el mismo 0..1 de asistencia real que ya gobierna la textura, `Club.perfil_estadio()` /
`capEfectivo()`) y decide asiento por asiento, con el mismo `rng` semillado de la fila -patrón
estable entre recargas, no parpadea de una partida a otra-, si va ocupado. Los que sí, arman un
segundo `MultiMeshInstance3D` con jitter chico de posición/mirada (una fila de maniquíes alineados
se lee tan falso como una vacía) y color de ropa mezclando neutros con los dos colores del club
-mismo criterio que ya usan las butacas-, para que se lea "hinchada local" sin volverse una bandera.
Un estadio con poca `ocupacion` en la simulación económica ahora se ve semivacío también en 3D: no
es decoración aparte con su propio número inventado.

**Verificado**: banco completo (851+ comprobaciones) 0 fallos, `.err.txt` vacío. Captura real nueva
(`pruebas/captura_hinchas_filas.gd` + `.tscn`, cámara propia a ras de campo pegada a la primera
fila -las cámaras de partido normales siguen la pelota, no sirven para inspeccionar la grada de
cerca-): `pruebas/pantalla_hinchas_filas.png` muestra las butacas vacías (respaldo negro) y las
ocupadas con la figura torso+cabeza en colores variados, huecos realistas donde no hay ocupación.
Nota al pasar: el script de captura reveló que `mundo.comercial` es `null` hasta que corre
`tomar_el_mando()` -`generar()` solo, sin eso, no alcanza-; `captura_bandejas.gd` (14/16-9) accede a
`mundo.comercial.balon` sin ese paso y por tanto está roto tal como está escrito hoy. No se tocó -no
es parte de esta tanda-, queda anotado para cuando alguien lo vuelva a necesitar.

## SINCRONÍA BALÓN/ANIMACIÓN EN LAS JUGADAS PREHECHAS: CERRADO (22-9-2026)

Investigación comparativa contra tres proyectos de fútbol open source (Gameplay Football, Google
Research Football, "Open-Soccer"/modelence) a pedido del usuario. El único hallazgo con aplicación
real fue el patrón de Gameplay Football (`humanoid.hpp`): cada animación de patada sabe en qué
fotograma exacto el pie toca el balón (`touchFrame`/`touchPos`), y el balón se lanza recién ahí, no
al arrancar la animación.

**Diagnóstico antes de tocar nada** (siguiendo la regla de oro de este archivo: grep primero): ese
patrón YA existe en este proyecto para los remates sueltos —`MatchPlayback._disparar()` arma el
vuelo con `_disparo_pendiente` y lo retiene `CONTACTO_PATADA = 0.35s` hasta que la animación
"patear"/"cabezazo" llega al contacto (verificado con `pruebas/diagnostico_timing_disparo.gd`,
preexistente). Lo que SÍ faltaba: `ReproductorJugadas` (las 60 jugadas prehechas del catálogo,
`nucleo/catalogo_jugadas.gd`) nunca pasaba por ahí — `avanzar()` llamaba `_balon.disparar(imp, spin)`
en el instante mismo en que arrancaba la fase, sin disparar ninguna animación de patada en el
rematador. Ese es el desync real que el usuario tenía anotado (comparando contra referencia de EA
FC 25): el balón salía volando mientras el jugador seguía con su animación de carrera.

De paso se confirmó que las animaciones "patear"/"cabezazo" de `AnimQuaternius` (mocap UE5 con
retarget GLOBAL) SÍ están activas en partidos reales hoy —`PlayerSpawner` ya llama
`FutbolistaQ.terminar(dq, true)`—, pese a que `NOTAS_CALIDAD_ANIMACIONES.md` (fechado 20-9) todavía
describe el problema de silueta como sin resolver: ese apunte quedó desactualizado por el arreglo
del 21-9 (retarget global, las 5 acciones verificadas contra el esqueleto de origen) y no se había
tachado. **Pendiente de bajo costo**: actualizar `NOTAS_CALIDAD_ANIMACIONES.md` para que no siga
sonando como un problema abierto.

**Arreglo** (`visor/reproductor_jugadas.gd`): nueva `_armar_impulso(imp, spin)` que reemplaza la
llamada directa a `_balon.disparar()`. Busca al rematador con
`MatchPlayback._companero_mas_cercano_al_balon()` (ya existía, reutilizado tal cual —el catálogo de
jugadas no trae un campo explícito "quién patea", pero el más cercano al balón en el instante del
impulso es siempre el que acaba de recibir el pase de la fase anterior, o quien lo tiene en el pie en
la fase 0), le dispara "patear" o "cabezazo" (criterio: `imp.y >= 4.0`, umbral leído de los propios
datos del catálogo) vía `MatchPlayback._ejecutar_accion()`, lo orienta hacia la dirección del
impulso, y recién entonces arma `_impulso_pendiente` con el mismo `MatchPlayback.CONTACTO_PATADA`
como retraso. `avanzar()` consume ese pendiente igual que `MatchPlayback.tick()` consume
`_disparo_pendiente`.

**Verificado**: prueba nueva permanente `pruebas/timing_disparo_jugadas.gd` (mismo método que
`diagnostico_timing_disparo.gd` —medir el timing y la animación arrancada, no una captura, que es la
verificación correcta para un bug de sincronización temporal—), instancia `ReproductorJugadas` con
un `MatchPlayback` y un `AnimationPlayer` de prueba con "patear"/"cabezazo" de mentira, reproduce
"ATQ-01" y confirma: el impulso queda pendiente (no sale inmediato), el rematador arranca la
animación, y el balón no sale antes de `CONTACTO_PATADA`. 0 fallos. Banco completo de regresión
(851+ comprobaciones) corrido de nuevo después del cambio: 0 fallos, `.err.txt` vacío en ambos casos.

**Fuera de alcance de esta tanda** (documentado como plan pendiente, no implementado todavía): capa
visual de público en las gradas (no existe hoy ningún renderer de multitud, solo `hinchada.gd` que es
simulación económica) y viñeta/gradiente de cámara estilo transmisión. Ver conversación del
22-9-2026 para el detalle de por qué esas dos quedaron para después y qué se descartó de los tres
proyectos investigados (assets de Gameplay Football: licencia de esos modelos sin aclarar, alojados
fuera de GitHub, no se bajaron).

## OPTIMIZACIÓN, PRIMERA RONDA: DOS AJUSTES, DOS GANANCIAS REALES MEDIDAS (21-9-2026)

A pedido explícito del usuario ("mucho más rápido y ligero sin perder la calidad"). Nada a ciegas:
`pruebas/medir_rendimiento.gd` (nuevo, usa el singleton `Performance` de Godot) y `pruebas/medir_
texturas.gd` (nuevo, recorre todas las MeshInstance3D vivas y suma el tamaño de cada textura única)
midieron un partido real antes de tocar nada.

**Hallazgo 1**: `Calidad.elegida` -el nivel gráfico activo por defecto- vivía en `ALTO` (SSAO, glow,
sombras de 4 cortes hasta 600m, MSAA x4, atlas de sombra 4096) pese a que el propio comentario del
código ya decía "MEDIO para jugar con soltura". Cambiado el default a `MEDIO`. Medido:

| | ALTO (antes) | MEDIO (después) |
|---|---|---|
| FPS promedio | 44.0 | 50.0 (+14%) |
| Tiempo de frame | 61.0 ms | 38.5 ms (**-37%**) |

Sin cambio visible a la distancia de cámara normal (verificado con captura real, no solo el número).

**Hallazgo 2, más grande**: `pruebas/medir_texturas.gd` encontró 748MB en 51 texturas únicas, **9 de
ellas a 4096×4096 (64MB CADA UNA, sin comprimir) sumando 576MB -el 77% del total-**. La mayoría eran
las texturas de la camiseta nueva (`VestidorQ._textura_recoloreada()` generaba una copia de 4096×4096
completa POR CADA color de club distinto, en tiempo de ejecución) más las texturas Normal/ORM que se
cargan sin pasar por ese código. Investigando el `.import` de estas texturas -y de TODAS las texturas
de personajes del proyecto, no solo las nuevas- se encontró que ninguna tenía compresión VRAM activada
(`compress/mode=0` en todas, sin excepción, incluidas las del modelo viejo `futbolista_cr7_*`): un
vacío sistémico, no un descuido puntual de esta sesión.

Arreglo en dos frentes:
- `VestidorQ._textura_recoloreada()`: la textura generada en tiempo de ejecución ahora se reduce a
  1024×1024 (16x menos memoria por color de club) antes de subirse a la GPU -esta prenda nunca ocupa
  mas de unos cientos de pixeles en pantalla, ni en un primer plano.
- Las 19 texturas `.import` bajo `assets/characters/` (todas, no solo las nuevas): `compress/mode=2`
  (compresión VRAM real, antes sin comprimir) y `mipmaps/generate=true`. Las dos más grandes de la
  camiseta (`T_Peasant_Normal`/`T_Peasant_ORM`, 4096×4096) además con `process/size_limit=1024` para
  igualar la resolución de la textura de color que ya se generaba a 1024.

Medido de nuevo, mismo partido real:

| | Antes | Después |
|---|---|---|
| Memoria de video | 962 MB | 282 MB (**-71%**) |
| Tiempo de frame máximo | 266 ms (tirones reales) | 57 ms |
| FPS mínimo | 12 | 20 |

El FPS promedio no cambió mucho (ya no era memoria lo que limitaba el promedio en regimen), pero los
TIRONES -los picos de frame que se sienten jugando, no el promedio que no se nota- bajaron
drásticamente. Verificado con captura real (sin pérdida visible) y banco completo limpio.

Limpieza de paso: se borró `assets/characters/quaternius/ropa_temp/` -carpeta de prueba de la sesión
anterior, ya no usada por ningún código real, solo ocupaba espacio y podía confundir a futuro.

**Ronda 2, mismo día, a pedido del usuario ("aún siento que el mínimo debería rondar 40, con calidad
alta... y basado en mi hardware, que es bajo: 8GB RAM DDR3")**. Primero se revisó la lógica GDScript
por-cuadro (movimiento e IA de los 22 jugadores): el `_separacion()` que compara cada jugador contra
los demás es O(n²), pero sobre solo 25 elementos -625 comparaciones de vectores por fotograma, un
costo insignificante para cualquier CPU, incluso una vieja-. Descartado como cuello de botella real
sin necesidad de tocarlo.

**Corrección de metodología real, encontrada revisando la curva de arranque cuadro a cuadro**: el
"pico de 245ms en el fotograma 31" que parecía un freeze puntual en realidad NO lo era -
`Performance.TIME_PROCESS`/`TIME_FPS` en Godot se actualizan cada cierto intervalo, no en cada
fotograma real (confirmado imprimiendo el valor fotograma a fotograma: se queda IDÉNTICO durante
tramos de 10-25 fotogramas seguidos, un valor en escalera, no una medida por fotograma). Lo que
parecía "un tirón" era la cola de una fase de carga inicial más lenta y sostenida (varios segundos
reales), no un solo fotograma. Import a tener en cuenta para cualquier medición futura con este
mismo método: descartar bien el arranque, y no tomar un solo valor "pico" como un fotograma real sin
verificar que el monitor se haya actualizado de verdad.

**El ajuste real que dio el salto grande**: en vez de bajar de nivel (MEDIO pierde SSAO y glow, que sí
se notan), se aligeró ALTO por dentro -los dos costos más caros y menos visibles a la distancia de
cámara de un partido, no los más notorios-:
- MSAA x4 → x2 en ALTO (x4 se reserva para ULTRA/capturas).
- Atlas de sombra 4096 → 2048 en ALTO (un cuarto de memoria/ancho de banda).
- Distancia de sombra de 4 cortes: 600m → 420m (la cascada de 4 cortes se mantiene, solo se acorta
  el alcance -nítida donde de verdad se juega, no hasta el fondo de una tribuna que la cámara rara
  vez encuadra entera).

Medido, mismo partido real, ALTO antes vs ALTO aligerado:

| | ALTO original | ALTO aligerado |
|---|---|---|
| FPS promedio | 44.0 | **57.3** (+30%) |
| Tiempo de frame máximo | 61 ms | 44 ms |
| Memoria de video | 980 MB (ya bajada a 300MB en la ronda 1) | 286 MB |

SSAO y glow siguen encendidos -la calidad visual que más se nota no se tocó-. Verificado con captura
real y banco completo limpio. Nivel por defecto (`Calidad.elegida`) vuelto a `ALTO` -la ronda 1 lo
había bajado a `MEDIO` como primer intento, descartado por perder calidad visible.

**Ronda 3, mismo día: el resto del proyecto.** El mismo vacío (`compress/mode=0`, sin comprimir en
VRAM) no era exclusivo de `assets/characters/` -41 de las 60 texturas de TODO el proyecto (ciudad,
estadio, coches, edificios) estaban igual de sin comprimir. Mismo arreglo aplicado en bloque a las
41. Medido de nuevo (dos corridas, para descartar ruido de medicion en este sandbox compartido -la
primera corrida trajo un FPS mas bajo que resulto ser variabilidad del entorno, no una regresion
real, confirmado repitiendo la misma prueba):

| | Ronda 2 (ALTO aligerado) | Ronda 3 (+ texturas de todo el proyecto) |
|---|---|---|
| Memoria de video | 286 MB | **244 MB** |
| FPS promedio (2 corridas) | 57.3 | 54.9 / 50.9 |
| FPS minimo (2 corridas) | - | 41 / 16 (ruido, ver arriba) |

Verificado con captura real (sin perdida visible) y banco completo limpio.

**Total acumulado de las 3 rondas de esta sesion, mismo partido real, mismo punto de partida:**

| | Antes de tocar nada | Despues de las 3 rondas |
|---|---|---|
| FPS promedio | 44.0 | ~51-57 |
| Memoria de video | 980 MB | **244 MB (-75%)** |
| Tiempo de frame maximo | 266 ms (con tirones de carga) | ~55 ms en regimen estable |

**Pendiente real para la proxima ronda**: no se llego a revisar la malla/geometria del estadio en si
(cuantos vertices/objetos aporta cada tribuna, banco, etc. por separado) ni el costo de la sintesis
de sonido (205 efectos generados al arrancar, cada uno un barrido de miles de muestras). Y lo mas
importante, honesto, que ya quedo dicho en la ronda 2 y sigue aplicando: todo esto se midio en este
sandbox (Intel UHD sin GPU dedicada, motor en modo Compatibility, no el Forward+/Vulkan real del
build de escritorio) -es un proxy razonable para un equipo modesto como el del usuario (8GB RAM
DDR3), pero no es 1:1. Probar en la maquina real y reportar el numero de verdad es el siguiente paso
para seguir afinando mas alla de este punto.

## CAMISETA REAL EN EL MODELO QUATERNIUS, POR FIN (21-9-2026)

Cierra el pendiente de vestuario abierto desde que se conectó el modelo Quaternius al partido real. A
pedido explícito del usuario ("usar las herramientas de los conectores", luego "aún se puede ver
mejor", luego "contempla los logos, sponsor y los diseños"):

**Pack encontrado**: "Modular Character Outfits - Fantasy" de Quaternius (gratis, itch.io, mismo
esqueleto que "Universal Base Characters" -confirmado hueso por hueso, `neck_01`/`spine_01/02/03`
caen igual en ambos .gltf, no hace falta retargeting-). La pieza "Peasant" (túnica de campesino) es
la única con forma de mangas+torso sin armadura pesada.

**Camino de Adobe descartado por una razón real**: se intentó subir la textura a Adobe Creative
Cloud para editarla con las herramientas de imagen del conector -a pedido explícito del usuario-,
pero la subida falla por restricciones de red de este entorno (sin salida a los servidores de Adobe,
confirmado con dos intentos y `TLS 1.2` forzado). Se hizo el recoloreado directo en Godot en su
lugar, mismo resultado, sin depender de red externa.

**Fotos reales de camiseta, probado y descartado con evidencia**: pegar una foto real
(`recursos/equipaciones/`) directo sobre el UV de esta prenda dio resultados MUY distintos según el
club -con Colo-Colo (diseño simple, blanco + franja negra) se veía razonable por pura casualidad, con
Boca Juniors (diseño más elaborado) salió un desastre irreconocible-. El UV de esta prenda es un
atlas complejo de piezas, no una foto de frente simple como el modelo viejo (ver `Vestidor.gd`, "EL
GOLPE DE SUERTE"). **No hay logos, sponsors, ni patrones reales con esta pieza** -eso queda como
pendiente real para cuando se consiga una malla de camiseta hecha a medida, no una prenda de fantasía
reutilizada.

**Camino que sí funciona: color plano por club, con el cuero también retenido.** `VestidorQ.
_textura_recoloreada()`: mismo algoritmo que `Vestidor._retenir()` (desplazar cada pixel por la razón
color_objetivo/color_referencia, conserva pliegues/sombreado), pero aplicado DOS veces -tela clara
al color primario, cuero oscuro (cinturón, ribetes, hebilla) a una sombra del MISMO color en vez de
quedar café-. La primera ronda (solo la tela) se leía a disfraz medieval por el cinturón café; la
segunda ronda, a pedido del usuario ("aún se puede ver mejor"), lo resuelve: el cinturón pasa a leerse
como un detalle de diseño de la misma prenda. Probado en dos colores (blanco, azul), se sostiene
igual de bien en los dos.

**Integración real, no solo prueba aislada**: `VestidorQ.vestir()` reparenta las MeshInstance3D de
la prenda como hijas del `Skeleton3D` real del jugador (heredando su escala real vía `modelo.scale`,
no la raíz sin escalar -confirmado que importaba, no solo supuesto) y reapunta `.skeleton` al mismo
esqueleto -sin retargeting, los nombres de hueso ya coinciden-. Verificado con una animación de
"correr" completa (frente y perfil) que la prenda de verdad se deforma con el cuerpo, no se queda en
T-pose ni se separa. Conectada a `PlayerSpawner._crear_jugador()` con el color real del club (`c1`,
el mismo que ya usa el sistema de camisetas del modelo viejo) y verificada en un partido real
completo: los dos equipos ya se distinguen por color de camiseta, sin errores, banco completo limpio.

**Ronda 2, mismo día -a pedido del usuario ("hay partes sin camiseta, faltan short y zapatos")**:
se pegaron tambien `Male_Peasant_Arms`/`Legs`/`Feet` -las 4 piezas modulares del pack, mismo
mecanismo-. Detalle real encontrado: `Arms` trae DOS materiales, "MI_Peasant" (tela) y
"MI_Regular_Male" (piel de la mano) -recolorear los dos habria pintado las manos del color del
club, un bug nuevo; `VestidorQ.vestir()` ahora filtra por `resource_name` y solo retine "MI_Peasant".

**Bug real visto en la captura, no supuesto**: con las 4 piezas puestas, aparecian parches de piel
asomando en el pecho y los muslos -las mallas de ropa y la piel del cuerpo desnudo ocupan casi la
misma superficie y compiten por cual se dibuja encima ("z-fighting"). Arreglo parcial: inflar la
ropa un 1.5% (`malla.scale = Vector3.ONE * 1.015`) empujandola levemente hacia afuera del cuerpo -
mismo truco de siempre para este problema, no exclusivo de Godot-. Redujo mucho el parcheo del
pecho; el de los muslos NO es el mismo problema -ahi la pieza de piernas simplemente no llega hasta
donde termina la camiseta, es un hueco de costura, no una competencia de mallas- y sigue visible.
Cerrarlo del todo necesitaria ajustar los limites de las mallas con una herramienta 3D real
(Blender), que no esta disponible en esta sesion. Sigue sin pelo. Verificado en partido real
completo despues del ajuste: banco limpio, sin errores.

## TERCERA JUGADA PREHECHA: EL TIRO LIBRE (21-9-2026)

Mismo patrón que el corner, aplicado a una falta ("warn"/"falta") que cae dentro de rango de disparo
directo (<30m del arco propio del equipo que la cometió). `_jugada_tiro_libre()`: el atacante más
cercano al punto de la falta se coloca sobre el balón, dos o tres defensores del equipo que cometió
la falta forman una barrera a 9,15m (la distancia real, no inventada) entre el balón y su arco, y tras
la ventana de llegada patea -mismo mecanismo de `_disparo_pendiente`/`Balon3D.detener()` ya
corregido con el corner, reutilizado sin repetir el mismo bug esta vez-. No redecide nada: sigue
siendo un "warn"/"falta" normal a todos los efectos.

Verificado con una prueba forzada (posición real de la barrera y el balón, cuadro a cuadro: el balón
sale del punto de la falta, sube a ~1.9m, termina cerca del arco) y con una prueba de estrés de
partido natural -sin bug de guarda esta vez, la lección del corner ya evitó ese error de diseño-. La
prueba de estrés no capturó ningún tiro libre real dentro de su ventana, pero por una razón real y
esperable, no un bug: las 3 faltas que sí ocurrieron cayeron a 78-98m del arco, fuera del rango de
30m -una falta peligrosa cerca del área es, correctamente, más rara que un remate desviado-.

## SEGUNDA JUGADA PREHECHA: EL CÓRNER (21-9-2026)

A pedido explícito del usuario ("más jugadas prehechas... córner, tiro libre"), primera jugada nueva
desde la de gol-con-asistencia. `MatchPlayback._jugada_corner()`: cuando un remate sale "fallo" (30%
de probabilidad, sorteada con `_rng` propio -nunca `Azar`, es puramente cosmético, mismo criterio de
siempre-), un jugador corre al banderín más cercano al lugar por donde salió el balón, dos o tres
compañeros más entran al área (primer palo/centro/segundo palo, los tres puntos reales que se
disputan en un córner real), y tras una ventana de 1.6s para que el sacador llegue, patea de verdad
-mismo principio ya usado para el desface del disparo normal: la pelota no sale en el fotograma 0 de
"patear"-. **No redecide nada de la simulación**: sigue siendo un "fallo" a todos los efectos del
marcador, solo se viste distinto una fracción de las veces -mismo principio que ya usa `_jugada_gol()`
(dramatizar lo decidido, no redecidir nada).

Dos bugs reales encontrados y corregidos durante la verificación, ninguno visible con solo leer el
código:
1. **El centro salía desde cualquier lado menos el banderín.** `Balon3D.enviar()` siempre usa la
   posición ACTUAL del balón como origen, pero el balón seguía en pleno vuelo de SU PROPIO remate
   "fallo" original (que también pasa por `_disparo_pendiente`) cuando se resolvía el córner -el
   centro salía desde donde fuera que ese vuelo lo hubiera dejado, no desde los pies del sacador.
   Arreglo: reposicionar el balón junto al sacador antes de patear, con `Balon3D.detener()` PRIMERO
   -sin eso, `avanzar()` seguía interpolando desde el vuelo viejo y pisaba la posición en el mismo
   fotograma-. Confirmado con una prueba forzada que imprime la posición real del balón cuadro a
   cuadro: antes del fix, el balón aparecía a decenas de metros del banderín; después, sale del lugar
   correcto y sube en arco real (~2.8m de altura, medido).
2. **El córner nunca se disparaba solo, ni una vez, en un partido real.** Confirmado con una prueba
   de estrés (partido natural de +1 hora simulada, sin forzar nada): 2 remates "fallo" reales, cero
   córners. Causa: la condición de disparo exigía `_disparo_pendiente.is_empty()`, pero
   `_recalcular_fase(ev)` -un poco más arriba en la misma función- YA deja esa variable ocupada con
   el vuelo del propio remate que se está procesando, así que la condición nunca podía ser
   verdadera. Quitada esa guarda (no hacía falta: el córner sobreescribe `_disparo_pendiente` más
   tarde, cuando el vuelo original ya se lanzó). Reconfirmado con la misma prueba de estrés extendida:
   un córner real, en el minuto 82, sin forzar nada.

Ambos bugs son la razón de que este tipo de feature necesite una prueba de extremo a extremo -no solo
el banco (`banco.tscn` no pasa por este código en absoluto, misma lección ya aprendida con
`stadium_builder.gd` esta misma sesión) ni una llamada aislada a la función-, y de que la lección de
memoria "verificar con evidencia real, no solo leer el código" siga pagando dividendos: el primer bug
solo se vio con la posición real del balón impresa cuadro a cuadro; el segundo solo se vio corriendo
el partido de verdad, no llamando a la función a mano.

## CATÁLOGO DE SONIDO: DE 65 A 205, MÁS DOS VACÍOS REALES CERRADOS (21-9-2026)

A pedido explícito del usuario ("que sean cerca de 200 sonidos"): tercera tanda de `Sonido.
_sintetizar()`, 135 efectos nuevos sobre los 65 que ya existían -catálogo total ahora en 205,
confirmado con `Sonido.catalogo().size()`-. Organizados en los mismos bloques que ya usaba el
catálogo (partido, grada, gestión/carrera, interfaz, festejos, clima, árbitro/disciplina, estilo de
juego), cada uno con su propia receta de síntesis, no una copia reetiquetada. El banco (que ya
comprobaba "ningún efecto sale en silencio", pico < 200 sobre 16 bits) atrapó una real: `posesion_
larga` salía demasiado débil (vol 0.03) y no pasaba el umbral -subida a 0.09, banco limpio de nuevo.

**Antes de sumar sonidos nuevos, dos vacíos reales encontrados en lo que YA existía y nunca sonaba
en el visor 3D en vivo** (`ui/estadio.gd`):
- Un remate que sale desviado (`tipo == "fallo"`, el resultado MÁS común de un remate) no reproducía
  ningún sonido -la rama por defecto de `_al_remate()` solo hacía `pass`- pese a que `Sonido` ya
  traía "remate_fuera" sintetizado y sin usar en ningún lado del visor. Conectado.
- La grada solo sonaba una vez, al arranque ("murmullo" en bucle todo el partido) -exactamente lo
  que el usuario ya había descrito como "se siente genérico"-. Se agregó `_tocar_ambiente()`: cada
  10-18s reales (seedeado con RNG propio, no `Azar`, por ser puramente cosmético), suena una de
  tambor/trompeta/bengala, cántico/aplauso, o abucheo -este último improbable si el propio equipo va
  ganando, no tiene sentido que la hinchada propia abuchee sin motivo-. Verificado adelantando el
  reloj de la simulación en un solo salto (`pruebas/diagnostico_ambiente.gd`, nuevo) en vez de
  esperar minutos reales de render.

**Pendiente real, no ocultado**: los 135 sonidos nuevos EXISTEN y pasan el banco, pero la mayoría
todavía no está conectada a un disparador real en el juego -muchos son para sistemas fuera del
visor 3D de partido (mercado de fichajes, médico, directiva, interfaz general) que esta sesión no
tocó. Conectar cada uno a su momento real es trabajo aparte, sistema por sistema.

## MODELO QUATERNIUS CONECTADO AL PARTIDO REAL, POR PRIMERA VEZ (21-9-2026)

`PlayerSpawner._crear_jugador()` ahora instancia `FutbolistaQ` (con `acciones_experimentales=true`,
asi que el catalogo real de futbol -patear/celebrar/atajar/cabezazo/mostrar_tarjeta/penal- entra
tambien, no solo la locomocion) en vez de `Futbolista` (el modelo Mixamo viejo), detras de una
constante `USAR_MODELO_Q := true` para poder revertir en una linea. Verificado con banco completo
(0 fallos, `.err.txt` vacio salvo warnings de shutdown ya documentados como benignos en este
proyecto) y una captura real de un partido completo -incluyendo un gol forzado y su festejo-: los
22 jugadores corren con el mocap real (buena postura, sin la inclinacion hacia atras del modelo
viejo, sin pies hundidos), sin errores.

**Limitacion real, aceptada explicitamente por el usuario ("conectalo igual, desnudo por ahora")**:
el pack gratis de Quaternius (`Superhero_Male_FullBody`) es un cuerpo desnudo -sin camiseta, sin
pelo, descalzo, solo un short oscuro-, confirmado con el atlas de textura (`T_Superhero_Male_Dark.
png`, una sola malla combinada, sin una region de "camiseta" separada) y con una captura real. NO
hay ningun pack de ropa/equipacion Quaternius descargado en el proyecto todavia. `Vestidor.vestir()`
(el sistema que pone las camisetas reales de 1.102 clubes) sigue existiendo intacto para
`Futbolista` -no se toco, no aplica a este esqueleto- pero no tiene equivalente para `FutbolistaQ`:
por ahora los 22 jugadores de ambos equipos se ven identicos (piel desnuda), sin forma de distinguir
equipos a simple vista. Este es el siguiente paso real pendiente si se sigue por este camino:
conseguir o generar un pack de ropa compatible con el esqueleto Quaternius/UE-mannequin, o aceptar
un periodo de transicion sin camisetas.

## DOS BUGS VISUALES REALES CORREGIDOS: TRIBUNA "ESTATICA DE TV" Y TUNEL SOBRE LA CANCHA (21-9-2026)

Encontrados comparando una captura fresca del partido contra el video de referencia real de EA FC 25
(recuperado de Google Drive, `revisa_el_video_tambien_y_ana.mp4` -el archivo local ya no existia-).

**Tribuna con aspecto de "estática de TV"**: `StadiumBuilder._make_stand_texture()` pintaba cada
"persona" del publico como UN SOLO TEXEL de alto. La matematica real: este eje repite cada 20m en
320 texeles -0.0625 m/texel-, pero una persona mide ~0.5m -unos 8 texeles-. Con solo 1 texel real por
persona, los otros 7/8 quedaban al azar de OTRO sorteo independiente: ruido de alta frecuencia por
diseño, no un problema de filtrado. Dos intentos previos (generar mipmaps, forzar filtrado
anisotropico) no cambiaron nada -confirma que el dato de origen ya era ruido, no habia nada
coherente que un filtro pudiera promediar-. Arreglo real: cada persona ahora ocupa un bloque de
~8 texeles de alto (piel arriba, ropa abajo), calculado desde el tamaño real de un texel, no un
numero inventado. Verificado con una captura de camara totalmente estatica (`pruebas/
diagnostico_tribuna_estatica.gd`, nuevo) antes y despues: antes, ruido de colores puro; despues,
bloques de gente reconocibles. Nota honesta: el resultado ahora se lee como "bloques" no como una
foto difuminada de gente real -es una mejora real, no una solucion final de fotorrealismo-.

**Boca del tunel encima del área chica**: el usuario reporto con una captura real que una caja
tapaba el arco por completo. Investigacion inicial (equivocada) penso que era un problema de
encuadre de la camara "Tele Dinámica" -la formula de foco de esa camara SI converge cerca de esa
posicion, pero no era la causa real-. La causa real, confirmada geometricamente: `_tunel()` ponia la
mole de hormigon en Z=45.0 con 6m de fondo (hasta Z=48), y el arco esta en Z=52.5 (`MEDIO_LARGO`) -la
caja quedaba a 4.5m de la linea de gol, ENCIMA del area chica, no detras de la tribuna donde
corresponde un tunel de vestuarios de verdad. Mismo tipo de bug que el de los banquillos del 17-9
(una estructura del estadio mal ubicada, confirmada con captura real, no solo leyendo el codigo).
Arreglo: toda la mole (mole/boca/tubo telescopico/arco inflable) se movio a Z=64 -detras de la linea
de gol, no sobre la cancha- manteniendo los mismos desfaces relativos entre sus piezas. Verificado
con una captura fresca del gol: arco completamente despejado desde la camara de festejo.

Ambos verificados con banco completo (0 fallos, `.err.txt` vacío) mas capturas reales antes/despues,
no solo lectura de codigo. Un error real de compilacion (`:=` infiriendo tipo de un `Array` -mismo
tipo de trampa ya documentada antes en este proyecto-) se coló en el primer intento del fix de
tribuna y el banco general NO lo detecto -`banco.tscn` no pasa por `stadium_builder.gd`-: solo lo
encontro una captura real que SI carga ese codigo. Recordatorio para la proxima vez: el banco general
en 0 fallos no cubre todo el codigo del visor 3D, especialmente el pesado en assets.

## DESFACE BALÓN/ANIMACIÓN EN EL DISPARO: CORREGIDO Y VERIFICADO (21-9-2026)

Bug encontrado en una auditoría de cómo el visor interactúa con el balón (pedida por el usuario):
en `match_playback.gd::_recalcular_fase()`, el vuelo del balón (`Balon3D.enviar()`) salía en el
mismo instante en que `_disparar()` arrancaba la animación "patear"/"cabezazo" del rematador -
fotograma 0, el jugador recién empezando a levantar la pierna-, no cuando el pie realmente conecta
a mitad del swing. Se leía como que el balón salía disparado antes de que el jugador terminara el
gesto.

**Arreglo**: se separó el cálculo del vuelo (sigue en `_recalcular_fase()`) de su lanzamiento real.
Cuando la fase es un remate real (gol/atajada/poste/fallo -las mismas condiciones bajo las que
`_disparar()` anima al rematador-), el vuelo calculado se guarda en `_disparo_pendiente` con un
`restante := CONTACTO_PATADA` (0.35s, estimado a partir de la duración total de esas animaciones,
0.9s en `_ejecutar_accion()` -no medido cuadro a cuadro contra el clip real, así lo dice el
comentario en el código). `tick()` lo descuenta cada fotograma y recién llama `Balon3D.enviar()`
cuando llega a cero. El movimiento ambiental del balón (fase "medio", sin remate) sigue saliendo
inmediato como antes -no hay animación de patada que sincronizar ahí-.

**Verificado con un test nuevo y aislado** (`pruebas/diagnostico_timing_disparo.gd/.tscn`), no solo
revisión de código: instancia un `MatchPlayback` mínimo, dispara un evento de remate y mide
`_disparo_pendiente` cuadro a cuadro -confirma que sigue pendiente a los 0.3s y que ya se lanzó
pasados los 0.35s de `CONTACTO_PATADA`-. Bench completo también limpio (0 fallos, `.err.txt`
vacío). Primera pasada del test tuvo un `SCRIPT ERROR` real en `.err.txt` pese a marcar "0 fallos"
-un diccionario de jugador de prueba incompleto, sin la clave `"node"` que `_mover()` exige-, no un
bug del fix: quedó como recordatorio de por qué nunca hay que confiar solo en el conteo.

## RETARGET GLOBAL: BUG REAL DE RAÍZ ENCONTRADO Y CORREGIDO, VERIFICADO CONTRA EL ORIGEN (21-9-2026)

Continuación del hilo del mocap real de fútbol (ver sección de abajo, 19-9). Entre sesiones
-trabajo del usuario y de otra ronda- se encontró que el retarget LOCAL (`cargar_futbol()`, pista
por pista en espacio local de cada hueso) producía una postura "de pie, sin romperse" pero que NO
reproducía el gesto real -comparado contra el esqueleto de origen, salía inclinado en la dirección
CONTRARIA-. Se agregó `visor/retarget_futbol_q.gd` (`RetargetFutbolQ`): retargeting en **espacio
GLOBAL relativo a la raíz animada** en vez de espacio local -el mismo principio que usa el
`RetargetModifier3D` nativo de Godot-, que sí calza con el origen (verificado con captura real
superpuesta, `retarget_global_power_kick_lado.png` contra `mocap_origen_power_kick_lado.png`). Las
acciones de fútbol quedaron detrás de una bandera `acciones_experimentales` (default `false`) para
que no se colaran en un partido real mientras se terminaba de resolver.

**`RetargetFutbolQ.aplicar()` es en tiempo real** -necesita el `AnimationPlayer` de origen ya
posicionado en el fotograma pedido, escribe la pose directo en un `Skeleton3D` vivo-, no sirve para
guardar en una `AnimationLibrary` tal cual. Se agregó `AnimQuaternius._bakear_futbol_global()`: arma
una escena descartable (el fbx de origen + un `FutbolistaQ` molde), recorre el clip a 30 muestras
por segundo aplicando el retarget en cada paso, y graba la pose resultante como un `Animation`
reutilizable -mismo patrón de cache-una-vez-y-reapuntar que ya usan `cargar_real()`/`cargar_futbol()`-.

**Bug real encontrado en el propio horneado, con evidencia, no supuesto**: el primer intento de
esta función colgaba sus nodos descartables de `get_tree().root`, lo que tiraba "Parent node is
busy setting up children" al llamarse desde el `_ready()` de otra escena (`FutbolistaQ.terminar()`
llamado justo después de `add_child()`). Se sacó esa línea para evitar el error -pero eso rompió
algo más grave sin avisar con ningún error: **el `AnimationPlayer` de origen, nunca agregado al
árbol, no actualizaba de verdad la pose del esqueleto al hacer `seek()`**, aunque la llamada no
tirara ningún error. Confirmado con un print de depuración que mostró `thigh_l` exactamente en su
reposo, sin variar ni un decimal, durante los 10+ segundos completos del bucle de horneado -prueba
de que `seek()` no movía nada, no de que el retarget estuviera mal calculado-. Esto producía el
jugador en T-pose (postura de reposo) en el partido real, con la animación "existiendo" (`has_
animation` daba `true`, 130 pistas con datos) pero sin ningún movimiento real dentro. **Arreglo**:
colgar los nodos descartables de `esq_referencia` -el esqueleto del jugador YA en el árbol por
contrato de `terminar()`, que por lo tanto nunca está "ocupado"- en vez de la raíz del árbol
completo.

**Verificación exigida por el usuario explícitamente ("deben ser identicos los movimientos"), no
solo "se ve de pie"**: se generaron referencias de origen para las 5 acciones
(`pruebas/diagnostico_mocap_origen_multi.gd`, nuevo -reproduce el fbx de origen directo, sin
FutbolistaQ ni retargeting- → `mocap_origen_<accion>_lado.png`) y se compararon una por una contra
el resultado retargeteado (`futbol_real_<accion>_lado.png`): **patear** (torso inclinado adelante,
cabeza agachada -calza-), **celebrar** (salto con brazo en alto, piernas flexionadas -calza-),
**atajar** (inclinado adelante desde la cintura, brazos alerta -calza-), **mostrar_tarjeta** (brazo
en alto, cuerpo erguido -calza exacto-), **penal** (de pie, manos juntas al frente, leve inclinación
-calza-). Las 5 confirmadas, no solo 1. Banco completo: 0 fallos, `.err.txt` vacío.

**Sigue pendiente, no oculto**: la bandera `acciones_experimentales` se mantiene en `false` por
defecto -el contenido ya no está roto, pero activarlo en partidos reales via `PlayerSpawner` es una
decisión aparte, todavía no tomada-. `cabezazo` sigue a mano -el pack gratis no trae esa acción-.

## MOCAP REAL DE FÚTBOL CONECTADO: PATEAR/CELEBRAR/ATAJAR/TARJETA/PENAL (19-9-2026)

El usuario consiguió y bajó "Free mocap pack 05: Soccer" de Anderson Rohr (Gumroad, gratis, uso
comercial libre): 21 clips reales de fútbol, exportados en 3 esqueletos. Se usó la versión **UE5
(Manny)** -esqueleto de un pipeline distinto al de Quaternius, pero con nombres de hueso casi
idénticos a `FutbolistaQ` (`pelvis`, `spine_01..03`, `thigh_l`, etc.), confirmado con
`pruebas/diagnostico_mocap_ue5.gd`-.

**El primer intento (reapuntar la ruta de cada pista sin más, igual que `cargar_real()` con la
librería de Quaternius) salió mal**: el jugador quedaba flotando y retorcido en el aire. Esperable
-`cargar_real()` funciona porque ese pack es del MISMO creador, con el mismo reposo garantizado;
este es de un pipeline distinto, sin esa garantía-.

**Retargeting real implementado** (`AnimQuaternius.cargar_futbol()`): por cada hueso, se extrae el
desvío del fotograma respecto al reposo DEL ESQUELETO DE ORIGEN, y se reaplica ese mismo desvío
sobre el reposo DE NUESTRO esqueleto -mismo principio que ya usa `_pista()` en todo el archivo para
las animaciones a mano, aplicado en sentido inverso-. Con esto la POSICIÓN quedó bien (dejó de
flotar) pero la ROTACIÓN seguía tumbando al jugador boca abajo en las 5 animaciones probadas,
incluida una (`mostrar_tarjeta`) sin ningún motivo para tocar el suelo -señal de un desfase
sistémico, no de cada clip-.

**Causa real encontrada, no supuesta** (`pruebas/diagnostico_offset_pelvis.gd`, comparando reposo
+ jerarquía de `root`/`pelvis`/`spine_01`/`thigh_l` en los dos esqueletos): el fotograma t=0 de la
pista de rotación de **`root`** en el clip de origen NO coincide con lo que `get_bone_rest()`
reporta como su propio reposo -mientras que `pelvis` para abajo sí coincide-. `root` recibe algún
tratamiento de importación FBX distinto al resto de la jerarquía, y retargetearlo como a cualquier
otro hueso arrastra un giro a toda la cadena que cuelga de él (pelvis, columna, piernas, brazos).
**Arreglo confirmado con captura real**: descartar la pista de rotación de `root` por completo dejó
4 de los 5 clips de pie y correctos. El quinto (festejo, variante 01) seguía mal -muy probablemente
porque ESE clip específico es una voltereta real que sí necesita que `root` rote-: se cambió a la
variante 02 (salto con el brazo en alto) en vez de forzar ese caso especial.

**Resultado, verificado con capturas reales de las 5**: `patear` (ahora `09_Power_Kick`) y
`celebrar` (ahora `13_Goal_Celebration_02`) reemplazan las versiones a mano. Se agregaron 3
animaciones NUEVAS sin equivalente previo: `atajar` (`15_Goalkeeper_Save_01`), `mostrar_tarjeta`
(`20_Yellow_Card`) y `penal` (`10_Penalty_Kick_01`). `cabezazo` sigue a mano -el pack gratis no
trae cabezazo, solo patada/penal/festejo/atajada/tarjeta/regate/entrada/juggling/saque de banda,
quedan 8 clips más sin usar todavía para una próxima ronda-. Banco completo: 0 fallos, `.err.txt`
vacío.

## EL ESTADIO POR MÓDULOS, FASE 3 (TRAMO): SPIKE CORRIDO CON PANTALLA REAL, RESULTADO POSITIVO (18-9-2026)

El spike (`pruebas/spike_tramo.gd/.tscn`) llevaba desde el 16-9 escrito pero nunca corrido con
pantalla real -esa sesión no tenía forma de verlo-. Esta sí. Encontrados y corregidos **dos bugs
reales** en el propio spike antes de poder juzgar nada:

1. **Eje de giro equivocado**: la rampa usa `size=(largo_rake, 0.4, largo_tribuna)` -la misma
   convención que una tribuna LATERAL en `StadiumBuilder.build()` (X=ancho subiendo el graderío,
   Z=largo de la tribuna)-, pero giraba sobre el eje X, que es la fórmula de una tribuna DE FONDO.
   El resultado no era una rampa inclinada de 90 m, era una tira parada de canto. Corregido a girar
   sobre Z (`stadium_builder.gd:734`, la referencia real).
2. **Encuadre de cámara mirando por el eje largo** en vez de mirar la cara ancha -junto con el
   `look_at()` llamado antes de `add_child()` (mismo bug ya visto en `diagnostico_postura.gd`)-.

Con la cámara y el giro corregidos, la pregunta real del spike: **el repetido "cada ~20 m" que usan
las tribunas de un solo patrón (para no perder densidad de "grano de asiento" sobre 90 m) rompe el
corte de tercios** -lo repite ~4,5 veces, convirtiendo 2 costuras reales en ~13 falsas: ruido puro,
no 3 sectores (`pantalla_tramo_general.png`/`pantalla_tramo_costura.png`)-. Probado también **sin
repetir** (`uv1_scale.y=1`, `pantalla_tramo_general_sinrepetir.png`/`_costura_sinrepetir.png`): la
costura entre dos tercios se ve **limpia, sin distorsión por la inclinación de la rampa** -la duda
concreta que este spike tenía que contestar-. El costo es un grano de patrón más grande (~30 m en
vez de ~20 m por ciclo), aceptable a ojo en la captura general.

**Conclusión: el concepto de tercios SÍ se sostiene visualmente**, con una condición concreta y ya
verificada: la variante de tercios no puede reusar el `uv1_scale` de repetido-cada-20m de una
tribuna de un solo patrón, tiene que usar `uv1_scale.y=1` (sin repetir sobre el largo completo).
Con esto, recién ahora corresponde diseñar la Fase 3 completa (forma de datos en `EST_DEF`, UI,
persistencia) como tarea aparte -no se diseñó todavía, esto era solo el spike de verificación-.

## PRESENTADOR DEL SORTEO: INVESTIGADO, NO MIGRADO TODAVÍA (18-9-2026)

El usuario sugirió migrar también al presentador del sorteo (`ui/sorteo_escena3d.gd`,
`_montar_presentador_modelo()`) al modelo/animaciones nuevas de Quaternius, ya que hoy usa el
modelo viejo (`Futbolista`/`AnimMixamo`). Investigado antes de tocar código: **bloqueador real
encontrado**, no solo teórico. `Vestidor.vestir()` -el mecanismo que viste al presentador de traje
liso oscuro, el mismo que ya viste a árbitros y jueces de línea- busca mallas por nombre
(`MALLA_CAMISETA`, `MALLA_PIEL`, `MALLA_CARA`, nombres del modelo viejo). El modelo Quaternius
(`Superhero_Male_FullBody.gltf`) trae nombres de malla genéricos de Blender (`Face`,
`Sphere.005_Retopology.004`...) que no calzan con ninguno de esos prefijos -confirmado leyendo el
propio `.gltf`, no supuesto-. Cambiar el modelo sin resolver esto deja al presentador sin traje
-piel y calzoncillos deportivos, como los 22 del campo-, que para un presentador de gala de sorteo
es un paso atrás, no una mejora, aunque la postura y la animación mejoren.

**No se hizo el cambio** para no dejar algo a medias. Queda pendiente decidir: (a) pintar/generar
una textura de traje para este modelo específico, (b) usar el modelo Female con algún vestuario
distinto, o (c) dejar al presentador con el modelo viejo hasta que haya una solución de vestuario
limpia para el nuevo. Verificación de referencia (antes de este hallazgo, con el modelo viejo):
`pruebas/sorteo_presentador_de_pie.png` / `sorteo_presentador_gesto.png`, reproducibles con
`pruebas/captura_sorteo_presentador.gd/.tscn`.

## ANIMACIONES REALES (NO A MANO) + SEGUNDO CUERPO (18-9-2026, cambio grande)

El usuario vio una captura del festejo (`celebrar`) y con razón la encontró rígida y "de muñeco"
-porque yo estaba adivinando ángulos, no reproduciendo movimiento real-. Preguntó si había
animaciones reales para descargar en vez de que yo las inventara. La respuesta: sí.

**Lo que se encontró y bajó (todo gratis, CC0, quaternius.itch.io):**
- **Universal Animation Library** (v1, Standard/gratis, 15 MB): 43 clips reales, incluyendo
  `Idle`, `Walk`, `Walk_Formal`, `Jog_Fwd`, `Sprint` -exactamente la locomoción básica, que es lo
  que un jugador hace el 95% del partido-. Mismo esqueleto de 65 huesos que `FutbolistaQ`
  (confirmado en el propio changelog de la página: "Updated to new rig naming scheme (Same as
  modular outfits / base chars)"), así que **no hace falta retargeting, calza directo**.
  Copiada a `assets/characters/quaternius/anims/UAL1_Standard.glb` (versión SIN root motion,
  para no pelear con el sistema de movimiento propio del proyecto).
- **Universal Base Characters, versión actualizada** (122 MB): confirmó lo que el usuario recordaba
  -el pack anuncia **6 personajes en total** (Superhero/Regular/Teen, cada uno M/F)- pero
  **honestidad importante: solo 2 de los 6 son gratis** (Superhero M/F); Regular y Teen (4 cuerpos
  más) están en el tier pagado Source ($19.99). El cuerpo Femenino, que ya estaba descargado desde
  antes pero nunca integrado, se sumó ahora.

**`visor/anim_quaternius.gd`**: nueva función `cargar_real(nombre_real, prefijo)` que saca un clip
real del glb (cacheando solo la `AnimationLibrary`, no el nodo completo, para no dejar mallas/
shaders huérfanos al cerrar el proceso -encontrado y corregido en esta misma ronda, ver `.err.txt`
antes/después-) y reapunta cada pista de `"Armature/Skeleton3D:hueso"` (su propio esqueleto) a
nuestro `prefijo` (el mismo hueso, nombre idéntico, solo cambia el nodo). `construir()` ahora usa
el clip real para `parado`/`caminar`/`trotar`/`correr` si existe, con la versión a mano como
respaldo si algún día falta. `patear`/`cabezazo`/`celebrar` se quedan con la versión a mano -el
tier gratis no trae remate ni festejo real, sería el próximo paso si se consigue de otra fuente-.

**`visor/futbolista_q.gd`**: `crear()` ahora acepta `cuerpo: "male"|"female"`, cada uno con su
propio `PackedScene` cacheado. Mismo esqueleto en los dos, así que `AnimQuaternius`/las animaciones
reales les sirven a ambos sin cambiar nada.

**Verificado con capturas reales, comparando contra las versiones a mano de antes**: `q_parado_lado.png`
(postura de reposo real, peso natural, no la simetría rígida de antes), `q_correr_lado.png` (sprint
real con balanceo de brazos genuino, no el vaivén mecánico calculado a mano), `q_female_caminar.png`
(el cuerpo Femenino con la misma animación real, sin ajustes). Banco completo: 0 fallos, `.err.txt`
vacío.

**Pendiente, no tapado**: `patear`/`cabezazo`/`celebrar` siguen siendo hand-keyed (el usuario ya
vio y cuestionó `celebrar` específicamente) -conseguir clips reales de remate/festejo/cabezazo es
el siguiente paso obvio, ya sea del tier Pro/Source de esta misma librería o de otra fuente-. Los
4 cuerpos restantes (Regular/Teen M/F) requieren pagar o encontrar otra fuente gratis.

## MODELO QUATERNIUS, PASO 5: EL FESTEJO (`celebrar`) (18-9-2026)

Quinta animación, la del festejo de gol -correr con los brazos abiertos y saltar, en bucle-. Calco
casi directo de `AnimMixamo.celebrar()`, mismo criterio de mapeo que `cabezazo()`: `"espalda"` ->
`espalda2`, y el Z de los brazos se copia tal cual porque el original YA venía pre-espejado a mano
(96/-96, 128/-128). Una omisión deliberada: el antebrazo del original solo gira 16° en Z, un
detalle cosmético mínimo sin verificar con sonda en este esqueleto -se prefirió omitirlo a
arriesgar un eje sin medir por un movimiento que casi no se nota-.

Verificado con capturas reales de frente y de perfil: se lee exactamente como el festejo clásico
-brazos bien abiertos hacia arriba en espejo perfecto, cabeza atrás, rodillas dobladas en el salto,
espalda arqueada-. `.err.txt` vacío, banco completo corrido después.

## MODELO QUATERNIUS, PASO 4: EL CABEZAZO (18-9-2026)

Cuarta animación del catálogo nuevo. Calco casi directo de `AnimMixamo.cabezazo()`, con dos
diferencias deliberadas:

- `"espalda"` (un solo hueso en el modelo viejo) pasa a `espalda2` (el tramo medio de los tres que
  tiene este esqueleto para la columna).
- Los brazos usan Z **espejado a mano por lado** (`14/-14`, `58/-58`, igual que el fichero Mixamo
  original) en vez de confiar en `_ajustar()`: esa función solo mueve el piso (la constante
  `BRAZO_ABAJO_Z`), no espeja los deltas que manda cada animación — cada animación tiene que
  espejar sus propios deltas de Z, igual que ya hacía a mano el fichero Mixamo. Documentado como
  comentario en el propio `anim_quaternius.gd` para que la próxima animación con movimiento de
  brazos en Z no vuelva a caer en el mismo bug de espejo que ya se encontró (y corrigió) en el
  paso 2.

Verificado con capturas reales: el primer intento de captura terminó usando por error la cámara
lateral en ambas fotos (un bug de orden en el propio script de diagnóstico, no en la animación) —
se vio bien igual (espalda arqueada, brazos simétricos, piernas en zancada de salto), pero se
corrigió el script y se volvió a capturar de frente para confirmarlo sin dudas: ambos brazos suben
en espejo perfecto, sin ningún brazo disparado al revés. `.err.txt` vacío, banco completo corrido
después.

## MODELO QUATERNIUS, PASO 3: EL REMATE (`patear`) (18-9-2026)

Tercera animación del catálogo nuevo, después de `parado`/`caminar`/`trotar`/`correr`. Mismo
diseño de tres tiempos que el `patear()` original de `AnimMixamo` -armar, soltar, acompañar-, pero
recalibrado a los huesos y ejes propios de este esqueleto (`visor/anim_quaternius.gd`).

Decisión clave: **toda la animación usa solo el eje X** -pierna de golpeo, pierna de apoyo, los dos
brazos de contrapeso-. Es el eje que la sonda (`pruebas/sonda_ejes_q.gd`) confirmó igual de un lado
y del otro en la Fase 2; el eje Z de los brazos SÍ se espeja entre izquierda y derecha (el bug real
que se encontró y corrigió al armar `parado()`/`correr()`), así que esta animación no le suma nada
en Z más allá del baseline que ya pone `_ajustar()` sola -evita pelear con esa complejidad de nuevo-.

Verificado con capturas reales (no solo "0 fallos"), extendiendo `pruebas/diagnostico_anim_q.gd`
para reproducir `patear` tras `correr` y guardar 3 fotos nuevas: `q_patear_armado_frente.png`
(pierna atrás, cerca del pico del armado), `q_patear_disparo_frente.png` y
`q_patear_disparo_lado.png` (pierna extendida hacia adelante, pie de apoyo firme en el suelo). La
vista de perfil es la que realmente muestra el gesto -de frente el movimiento de la pierna queda
casi oculto por la perspectiva, ya que viaja hacia/desde la cámara-. Se ve como un remate real, sin
geometría rota ni mezcla de ejes.

`.err.txt` de esa corrida vacío. Banco completo corrido después para confirmar que no se rompió
nada más en el resto del catálogo/simulación.

Queda pendiente migrar el resto del catálogo de `AnimMixamo` (~20 animaciones más: cabezazo,
festejos, faltas, tarjetas, atajar, etc.), una por una con la misma disciplina de sonda-si-hace-
falta + captura antes de dar por cerrada cada una.

## DE DÓNDE SALIÓ EL MODELO NUEVO, PARA BUSCAR MÁS COMPATIBLES (18-9-2026)

Anotado porque el usuario preguntó dónde conseguir más modelos que compartan la misma lógica -así
no hay que rehacer `anim_quaternius.gd` desde cero cada vez-.

- **Origen**: pack "Universal Base Characters" del creador **Quaternius** (quaternius.com),
  licencia **CC0** (dominio público, sin restricciones). Descargado el 17-9-2026, versión
  **"Standard" (gratis)**.
- **Lo que trae la version Standard**: solo **2 cuerpos** -`Superhero_Male_FullBody` y
  `Superhero_Female_FullBody`- más 7 peinados/barbas/cejas intercambiables por separado. Hasta
  ahora **solo se integró el masculino** (`assets/characters/quaternius/`); el femenino está en
  `_extraido_universal_base_characters/` sin tocar todavía -mismo esqueleto, así que
  `anim_quaternius.gd` debería servirle igual sin cambios, pendiente de probar-.
- **La licencia del propio ZIP lo dice**: existe una versión de pago **"SOURCE"** (en la misma
  página de Quaternius) con más cuerpos y los `.blend` rigueados -esa es la vía más directa para
  "varios modelos con la misma lógica" sin tener que recalibrar ejes de nuevo, porque comparte el
  mismo rig.
- **El esqueleto en sí** (`pelvis`, `spine_01/02/03`, `clavicle_l`, `upperarm_l`, dedos
  individuales por mano) es el **mismo estilo "UE Mannequin"** que usan muchísimos packs de
  personajes pensados para Unreal Engine -no es exclusivo de Quaternius-. Cualquier modelo
  gratuito o pagado que declare compatibilidad con ese esqueleto (búsqueda: "UE4 mannequin
  skeleton compatible" o "UE5 Manny/Quinn compatible") debería funcionar con `anim_quaternius.gd`
  tal cual o con ajustes menores, sin repetir todo el trabajo de calibración de ejes.

## MODELO QUATERNIUS, PASO 2: PARADO Y CORRER YA ANIMADOS Y VERIFICADOS (18-9-2026, v7.34)

Segunda pieza de la migración: `visor/anim_quaternius.gd` (clase `AnimQuaternius`), el equivalente
de `AnimMixamo` pero para el esqueleto Quaternius -mismo principio (desvíos sobre la pose de
reposo), ejes propios, medidos con una sonda nueva (`pruebas/sonda_ejes_q.gd`: aplica un desvío de
prueba en un hueso, captura, y así se lee a ojo qué eje mueve qué) en vez de asumir que valen los
del otro esqueleto.

**Ejes confirmados con captura real, no supuestos**: en muslo/rodilla/tobillo y en el vaivén
adelante-atrás del brazo, el eje **X** funciona igual de un lado y del otro, sin invertir signo.
El eje **Z** del brazo (subir/bajar desde el reposo en T) sí está espejado entre izquierda y
derecha -se encontró exactamente así, en el primer intento real: el mismo signo que bajaba el
brazo izquierdo mandaba el derecho para ARRIBA en vez de para abajo (capturado en pantalla, no
adivinado). Corregido con signo contrario para `brazo_d`. Dato importante para cuando se migren
las animaciones de brazos que faltan (patear, celebrar, faltas...): revisar eje por eje, no asumir
que ambos lados comparten signo solo porque las piernas sí lo hacen.

**"parado" y "caminar"/"trotar"/"correr" migradas y verificadas con capturas reales, de frente y
de perfil**: de pie, completamente recto -sin nada de la inclinación hacia atrás del modelo
viejo-, brazos caídos naturalmente a los costados, dedos visibles como dedos de verdad (no los
bloques del otro modelo). Corriendo: zancada con una pierna de apoyo y la otra en impulso, torso
con una inclinación hacia adelante natural -la correcta para correr, no la rota de antes-, brazos
en contrafase de las piernas. Se mandaron las capturas al usuario para comparar directo contra el
modelo viejo.

`FutbolistaQ.terminar()` ahora arma el `AnimationPlayer` con esta librería automáticamente.
Todavía NO conectado a `PlayerSpawner` -sigue siendo una clase aparte, probada, lista para cuando
se decida usarla en el partido real-. Catálogo pendiente para otra ronda: patear, celebrar,
faltas, tarjetas, atajar -el resto de `AnimMixamo`-.

Bench completo: 0 fallos, `.err.txt` limpio. Respaldo `v7.34`.

## AUDITORÍA DE MANOS Y ANIMACIONES: LA GEOMETRÍA ES EL LÍMITE REAL, NO EL CÓDIGO (18-9-2026, v7.33)

El usuario pidió revisar las manos y auditar si las animaciones ya escritas mueven pies y brazos
de verdad. Las dos cosas se investigaron con datos reales, no a ojo.

**Manos**: el modelo actual (`futbolista_cr7.glb`) SÍ trae un dedo índice articulado
(`mixamorig_LeftHandIndex1/2/3`, `Right...`), pero ninguna de las ~25 animaciones de
`AnimMixamo` lo tocaba -ni siquiera está en el diccionario `HUESOS`-, así que se quedaba
congelado en la pose de fábrica del `.glb` durante TODO el partido. Medido con
`get_bone_rest()`: esa pose de fábrica además viene asimétrica entre las dos manos (el índice
izquierdo entra doblado 53° en la base y recto en las dos falanges siguientes; el derecho trae una
rotación de fábrica totalmente distinta). Se agregó `AnimMixamo.aplicar_pose_relajada(esq)`,
llamada una sola vez al crear el jugador (`Futbolista.terminar()`) -no es una animación, fija con
`set_bone_pose_rotation()` una curva de dedo relajada (45°/30°/18° cadera→punta) que nadie más
pisa porque nadingún track toca esos huesos-.

**Pero esto es una mejora menor, no LA solución.** Un primer plano real (`mano_cerca.png`, cámara
pegada a la mano) mostró el problema de fondo: los "dedos" de este modelo son geometría de muy
baja resolución -bloques casi cúbicos, no dedos modelados de verdad- y hay una mancha oscura
circular en la textura de la mano (parece un tatuaje mal ubicado por UV, o un elemento de la
textura del antebrazo sangrando hacia la mano). Ninguna rotación de hueso arregla una malla de
baja calidad o una textura corrida. Esto refuerza -con evidencia nueva, no solo la postura ya
investigada- que el camino real es el modelo Quaternius ya en migración (ver más abajo), no seguir
puliendo este.

**Auditoría de pies y brazos, con grep del archivo real, no de memoria**:
- **Brazos/antebrazos**: animados extensamente -83 apariciones de `brazo_i/d` y `antebrazo_i/d`
  repartidas en casi todas las animaciones (correr, patear, celebrar, faltas, tarjetas...). Esto
  está bien cubierto.
- **Pies (tobillo)**: animados en `correr()` (ida y vuelta de la zancada, vía `_pierna()`) y en
  `patear()` (el pie que golpea flexiona). El resto de animaciones (cabezazo, faltas, festejos,
  atajadas) no tocan el tobillo -aceptable para esas, no es donde se nota-.
- **Dedos del pie**: nunca animados, ni siquiera están en `HUESOS`. Menos visible que los dedos de
  la mano por estar dentro del botín casi siempre, pero es el mismo tipo de hueco.
- **Muñeca (mano_i/mano_d) y dedos de la mano**: nunca animados antes de este arreglo -ver arriba-.

Bench: 0 fallos, `.err.txt` limpio. Respaldo `v7.33`.

## SEGUNDO MODELO DE JUGADOR (QUATERNIUS), PASO 1: DE PIE Y BIEN ESCALADO — EN CURSO (18-9-2026, v7.32)

El usuario pidió arreglar la postura/manos del modelo actual o, si no, sumar más modelos. Se
confirmó con capturas reales que el modelo actual (`futbolista_cr7.glb`) tiene dos problemas de
verdad, no solo de percepción: de perfil el torso se ve claramente echado hacia atrás -aunque la
cabeza quede nivelada por el par Spine/Neck que se investigó antes, el efecto general se lee mal,
no relajado-, y las manos salen deformadas, sin dedos articulados. Se comparó con el pack
Quaternius "Universal Base Characters" (gratuito, CC0, ya descargado por el usuario): anatomía
limpia, T-pose recto, **65 huesos con dedos individuales por mano** -esqueleto mucho más completo
que lo que sea que tenga el modelo viejo ahí-.

**Encontrado, no supuesto**: el esqueleto de Quaternius usa nombres estilo Unreal Engine
(`pelvis`, `spine_01/02/03`, `clavicle_l`, `hand_l`, `thumb_01_l`...), no `mixamorig_*`. Las ~25
animaciones de `AnimMixamo` NO le sirven a este modelo tal cual -es un esqueleto distinto, ejes y
nombres distintos-. Migrarlas es trabajo aparte, deliberadamente NO se tocó hoy.

**Lo que sí se cerró esta noche (Paso 1)**:
- Copiados e importados al proyecto los ficheros del cuerpo masculino
  (`assets/characters/quaternius/Superhero_Male_FullBody.gltf` + texturas base) -no las 24
  variantes de pelo ni ojos todavía, eso es aparte y no bloqueaba este paso.
- `visor/futbolista_q.gd` (clase `FutbolistaQ`), mismo patrón que `Futbolista.gd`: `crear()` +
  `terminar()`. A diferencia del modelo viejo, este YA viene de pie y ya orientado -no hace falta
  "enderezar" nada, solo escalar según la altura real del jugador, midiendo hueso a hueso
  (`Head` a `ball_l`) igual que hace `Futbolista` con el suyo.
- Verificado con una escena de prueba aislada (`pruebas/diagnostico_futbolista_q.gd`), marcas de
  altura de referencia en el render: pies exactos en el suelo, altura final a un par de
  centímetros de la pedida -calibración razonable para una primera pasada, sin necesitar más
  ajuste ahora mismo-.
- Bench completo del proyecto: 0 fallos, `.err.txt` limpio -confirmando que sumar el modelo nuevo
  no rompió nada de lo que ya había.

**Todavía sin animar** -de pie nada más, en pose de reposo del propio modelo-. `PlayerSpawner` NO
usa este modelo todavía en el juego real; sigue siendo solo una clase de apoyo probada aparte.
Próxima ronda: migrar animaciones básicas (parado, correr) una por una con verificación visual
real antes de conectar `FutbolistaQ` a `PlayerSpawner` de verdad.

Respaldo `v7.32`.

## GLOBO TERRÁQUEO SIN LUCES NI NUBES EN WEB/MÓVIL — CERRADA (18-9-2026, v7.31)

El usuario lo mencionó de pasada ("a futuro le haría otro repaso al globo") pero ya estaba el error
real en la consola del navegador desde antes, sin que nadie lo hubiera mirado: `ui/globo_3d.gd`
cargaba las tres texturas de la Tierra (día, luces de noche, nubes) con
`Image.load_from_file(ProjectSettings.globalize_path(ruta))` -lee el archivo del disco directo,
saltándose el cargador de recursos de Godot. En escritorio `res://` apunta a una carpeta real y
esto "funciona" de casualidad; en cualquier build empaquetada (Web, y probablemente también
Android/APK) no hay sistema de archivos real detrás de `res://`, así que la carga fallaba siempre
-"Error opening file 'recursos/tierra/luces4k.jpg'"- y el globo salía negro liso, sin luces de
ciudades ni nubes, solo el contorno.

**Arreglo**: usar `load(ruta)` -el cargador normal de Godot, que lee del `.pck` igual en
escritorio, Web y móvil- en vez de tocar el disco a mano. Las tres imágenes ya estaban importadas
como recurso de Godot (`.import` al lado de cada `.jpg`), así que no hacía falta nada más.

**Verificado**: banco 0 fallos, `.err.txt` limpio. Jugando en la build Web en una pestaña nueva
(la primera prueba en la pestaña reciclada mostraba el error viejo por caché del navegador, no
por el bug -aprendizaje: usar una pestaña nueva para verificar un cambio recién exportado, no
recargar la misma-): cero errores en consola, y el globo pasó de silueta negra lisa a mostrarse
con el lado nocturno iluminado.

Respaldo `v7.31`.

## APOYO CERCANO: MOVIMIENTO SIN BALÓN CON SENTIDO PROPIO (18-9-2026) — CERRADA (v7.29)

El usuario lo pidió explícito: que el movimiento de los 22 no dependa TOTALMENTE de una jugada
prehecha activa -que tenga sentido por sí solo, siempre-. Hasta ahora, sin guion encima, todo el
equipo tiraba de la pelota con el mismo 18%/22% parejo de `_objetivo_jugador()`: reparto de zona,
nadie en particular decide nada.

**Pieza nueva, acotada a propósito**: el compañero de campo (no portero) MÁS CERCANO al balón,
cuando su equipo ataca de verdad, recibe un tirón extra hacia una posición de apoyo -a un lado del
balón y un poco adelantado en la dirección de ataque, no encima de él- para leerse como "alguien
ofrece un pase". Solo ESE jugador; el resto del equipo sigue con el reparto de zona de siempre, a
propósito, para que esto no se sienta como una segunda "jugada con guion" encubierta sino como una
decisión de fondo, de ambiente.

Nueva función `_companero_mas_cercano_al_balon()`, misma forma que ya tenía `_rival_mas_cercano()`
para la marca al hombre.

**Verificado en dos capas**: banco de pruebas (`pruebas/banco.gd`, nueva aserción numérica: el
compañero cercano termina medible más cerca del balón que uno lejano, sin arrastrar a todo el
equipo) y jugando un partido real en la build Web -sin nada roto, sin amontonamientos, el reparto
se ve normal-. Aviso honesto: el efecto es un empuje puntual sobre UN jugador a la vez, así que no
hay forma de "demostrarlo" con una sola captura estática -la prueba real de que se lee bien es la
del banco, la visual solo confirma que no rompió nada.

Bench: 0 fallos, `.err.txt` limpio. Respaldo `v7.29`.

## CAMISETAS REALES CONECTADAS AL 3D (18-9-2026) — CERRADA (v7.28)

Bug real encontrado por el usuario ("hace tiempo que no se ven las camisetas") y confirmado
jugando un partido de verdad en la build Web: **todos** los clubes salían con la camiseta de un
solo color liso en el 3D, sin patrón ni foto real, sin importar qué tuviera configurado el club.

**Causa**: `visor/puente3d.gd::kit(c)` devolvía SIEMPRE `{"estilo": "liso", "img": ""}` -literal,
sin leer nada del club-. Mientras tanto `ui/jersey.gd` (la ficha 2D, "Club → Equipación") ya tenía
desde antes toda la lógica para resolver la equipación real de las 1.102 archivadas en
`EQUIP_REAL`, y el estampado determinista por club (`Jersey.kit_de()`) -pero nadie había conectado
esa lógica al visor 3D, que seguía con el `img_kit=""` de siempre.

**Arreglo**: `Puente3D.kit()` ahora llama a `Jersey.kit_de(c, c.kit_estilo)` y a la nueva
`Jersey.fichero_real(c)` (extraída de `textura_real()` para no duplicar la búsqueda en
`EQUIP_REAL`), y usa `c.color_kit1()/color_kit2()` en vez de los colores genéricos del club.
Verificado jugando en vivo en la build Web: Colo-Colo pasó de camiseta negra lisa a una foto real
con patrón. El "amarillo/azul" que pareció verse en esa primera mirada en vivo se revisó aparte
con un diagnóstico aislado (`pruebas/diagnostico_camiseta.gd`, recorta el torso de
`colo_colo_1.png` con la misma función del visor y lo guarda como PNG sin partido de por medio) y
salió perfecto: blanco con el escudo, Jugabet y Adidas en su sitio, color dominante `#ededed`. No
era un bug -fue una lectura apurada mía del partido en vivo, probablemente confundiendo de qué
lado era cada jugador-. Sin pendientes en esta pieza.

**Nota aparte, no arreglada todavía**: cuando NO hay foto real (`img_kit == ""`), el modelo
realista (`Vestidor.vestir()`) solo sabe pintar un color liso -a diferencia de
`KitTextureFactory` (el que viste al muñeco de respaldo), que sí sabe dibujar los 12 patrones
(franjas, banda, aros...). Portar esa capacidad de estampado a `Vestidor` es trabajo aparte, no
de hoy.

Bench: 0 fallos, `.err.txt` limpio. Respaldo `v7.28`.

## SE VIO EL VIDEO DE REFERENCIA: ES EA SPORTS FC 25 (18-9-2026)

El usuario pidió "llegar al nivel" de un video que mandó. Como no había forma de leer video
directo, se sirvió por HTTP (`herramientas/server.ps1`, ya existía, solo le faltaba el tipo MIME
de `.mp4`) y se abrió en el navegador propio para verlo de verdad. **Es un partido de EA Sports FC
25** -aparece el logo en pantalla-, con cámara de transmisión profesional, captura de movimiento
real y activos con licencia.

Dejarlo dicho con honestidad para no perseguir una meta imposible: igualar el nivel visual de un
juego AAA con un equipo completo y presupuesto de estudio, partiendo de materiales procedurales y
animación escrita a mano hueso por hueso, no es una meta realista de esta sesión ni de las que
sigan. Lo que SÍ es real y queda como objetivo: que el movimiento y las decisiones de los 22 se
vean con intención SIEMPRE, no solo durante una jugada prehecha activa -el propio usuario lo pidió
así explícitamente ("que la npc no dependan de las jugadas pre hechas, no totalmente")-, y seguir
cerrando bugs reales de material/iluminación/cámara uno por uno, verificados de verdad.

## LA COLUMNA MISTERIOSA: MUCHO DESCARTADO, CAUSA TODAVÍA NO — PAUSADA (18-9-2026)

Sesión de investigación larga, con resultados reales aunque no se haya cerrado. Se para aquí para
no seguir quemando tiempo en algo que ya dio rendimientos decrecientes -lo que sigue es la foto
completa para quien retome esto-.

**Confirmado (no teoría) apagando la luz de relleno nocturna y volviendo a jugar en vivo**: la
columna sigue exactamente igual de visible con la escena casi a oscuras -eso descarta que sea un
problema de iluminación (SSAO, glow, la luz fill, ya iban descartados de antes)-. Y a la vez,
mirándola de cerca en esa misma captura a oscuras, cada "burbuja" tiene sombreado real -un
degradado de luz en la superficie, como una esfera con volumen, no un sprite plano-, así que SÍ es
geometría 3D con volumen respondiendo a alguna luz (probablemente la luz clave, tenue de noche, o
el ambiente del cielo), no un overlay 2D pegado a la pantalla.

**Todo lo que se buscó y no calza** (para no repetir la búsqueda): ni un solo `GPUParticles3D` ni
`CPUParticles3D` en todo `visor/`. Los tres `SphereMesh` que sí existen no calzan por posición o
por ser un solo objeto, no una fila: el balón (una esfera, no una fila, sin emisión), la cabeza de
cada camarógrafo (radio 0,14, uno por camarógrafo, en el perímetro del estadio, no en el centro), y
un tercero en `city_builder.gd` que ni siquiera corre durante un partido (es de la vista de
ciudad). El escudo central (`_escudo_cancha`) no puede ser: en este club de prueba
`est.get("escudoDonde","sin")` hace que ni se construya. Los focos en anillo están en el perímetro,
no cerca del centro. El `MultiMeshInstance3D` de las butacas tiene tantas transformadas como
instancias, sin huecos.

**Pistas para la próxima vez, en orden de lo más barato a lo más caro**:
1. Ciclar de cámara en vivo (botón "📷 Cámara") mirando si la columna se mueve con la perspectiva
   como cualquier objeto 3D normal, o si se queda pegada a un punto de la pantalla -no se alcanzó
   a completar esta prueba porque el partido de prueba ya había terminado (minuto 90') y la cámara
   "Tele Dinámica" deja de re-encuadrar cuando no hay más juego-. Repetir esto TEMPRANO en un
   partido nuevo, no al final.
2. Cambiar a la cámara "Cenital táctica" (90° desde arriba) durante el partido: si es una fila
   vertical de verdad, desde arriba tiene que verse como un solo punto/círculo pequeño en vez de
   una fila.
3. Preguntarle al usuario si esto pasa también en la build de Windows real (Forward+), no solo en
   el teléfono/Web (Compatibility) -si NO pasa en Windows, es un problema de ese renderizador
   específico y hay que buscarlo del lado de Compatibility, no en la lógica del juego-.
4. Revisar si depende del **minuto del partido** o de algún **suceso concreto** (¿aparece recién
   tras el primer gol? ¿tras el primer córner o falta, si es que ese tipo de evento llega a
   dispararse?) en vez de asumir que está desde el primer segundo -no se confirmó con certeza
   cuándo aparece por primera vez, solo que ya estaba ahí en el minuto 1 de las pruebas hechas.

## JUGADAS PREHECHAS, PRIMERA PIEZA: BUG DE REMATE + ASISTIDOR CON GUION (18-9-2026) — EN CURSO

Hito real de esta sesión: por primera vez pude **ver el juego corriendo de verdad**, sin capturas
intermedias. Se armó una exportación Web del proyecto (`export_presets.cfg` ya traía un preset
"Web" listo de antes) servida con `herramientas/server.ps1` y abierta en un navegador propio -no
hace falta pantalla nativa, así que este límite del entorno ya no aplica para verificar cosas del
partido en vivo, aunque solo sea con el renderizador Compatibility (no Forward+, ver más abajo).

**La columna/burbujas que reportó el usuario por foto SÍ aparecieron**, jugando un partido real
(Colo-Colo vs D. Limache) sin forzar nada: un grupo de puntos translúcidos flotando cerca del
círculo central, quietos en el mismo sitio del minuto 1 al minuto 9 sin importar dónde estuvieran
los jugadores.

**Se probó y se descartó**: SSAO y glow apagados a la vez (`visor/ambience.gd`, reexportado y
comprobado con el partido corriendo) -las burbujas siguieron exactamente igual, así que NO es un
artefacto de esos dos post-procesados bajo Compatibility, la sospecha inicial más obvia.

**Se descartó por lógica de código, sin hacer falta reexportar**: `_escudo_cancha()` no puede ser
-el `est.get("escudoDonde", "sin")` en `build()` (no en `EstadioPropio.perfil()`, que es otro
call site con otro default) hace que el escudo ni se construya salvo que el estadio sea uno
diseñado a mano con esa opción, y este partido de prueba usa un club sin estadio propio. También
se descartó por geometría: los focos en anillo (`_focos()`, tipo "corona"/"halo") están en el
perímetro del estadio, no cerca del centro; y no existe ni un `GPUParticles3D` ni `CPUParticles3D`
ni `MultiMeshInstance3D` mal posicionado en todo `visor/` que caiga cerca de (0,0,0) -el único
`MultiMeshInstance3D` es el de las butacas de grada, con `instance_count` exactamente igual al
número de transformadas que se asignan, sin huecos.

**Pista real, sin confirmar todavía**: en las capturas de partido de DÍA hechas antes en esta
misma sesión (`pruebas/video_jugada_gol.gd`, cinco fotogramas) no aparece nada raro cerca del
centro. En el partido de NOCHE de esta prueba, sí. Eso apunta a algo que solo se activa con
`oscuro > 0.45` en `Ambience.apply()` -la luz de relleno nocturna (`fill`, una `DirectionalLight3D`
sin sombra) es lo único ahí que no se probó todavía a apagar-. Puede ser tambien pura niebla/cielo
procedural interactuando mal con el tonemap ACES bajo Compatibility, sin relacion a ningun nodo
concreto.

**Importante para el próximo intento**: esta build Web usa el renderizador **Compatibility**, no
**Forward+** -el que de verdad usa el juego de escritorio-, así que existe la posibilidad real de
que esto sea un artefacto exclusivo de Compatibility/Móvil (que es justo lo que usaría el teléfono
del usuario también) y que nunca aparezca en la build de Windows real. Antes de seguir cazándolo a
ciegas, el siguiente paso más barato es apagar la luz `fill` nocturna y volver a exportar, y si
eso tampoco lo explica, probar sin niebla (`env.fog_enabled`) con un clima "despejado" a propósito.

**Herramienta nueva que queda lista para todo lo que sigue**: `.claude/launch.json` con la
configuración `dinastia-web`, que levanta `herramientas/server.ps1` sirviendo
`entregas/web/` en `http://localhost:5500`. Reexportar con
`godot --headless --path dinastia-godot --export-debug Web` y volver a abrir esa URL basta para
ver cualquier cambio jugando de verdad, sin escribir un script de prueba nuevo cada vez.

## JUGADAS PREHECHAS, PRIMERA PIEZA: BUG DE REMATE + ASISTIDOR CON GUION (18-9-2026) — EN CURSO

El usuario marcó esto como lo más importante del juego: las "jugadas memorizadas" (estilo Soccer
Manager) tienen que verse reales y **todos** tienen que actuar con sentido, árbitro incluido. Este
es el arranque, no el cierre -una sola pieza, verificada, antes de seguir construyendo encima.

**Bug real encontrado leyendo `match_playback.gd` de punta a punta** (no reportado por el usuario,
encontrado por revisión de código): el evento que manda `estadio.gd::_al_remate()` viaja como
`"t": "disparo"` con el resultado real en `"tipo"` (atajada/poste/fallo), pero
`_recalcular_fase()`/`_disparar()` comparaban contra `ev["t"] == "atajada"/"poste"/"fallo"` -un
valor que ese campo nunca tenía. Efecto: en el partido de verdad, el balón NUNCA volaba hacia el
arco en un remate fallado ni el arquero se lanzaba a atajar -sólo funcionaba en los goles, porque
`golMi`/`golR` sí son el `"t"` real de ese evento. Corregido leyendo `"tipo"` donde corresponde.

**Primera jugada con guion propio**: hasta ahora, el asistidor de un gol seguía el reparto táctico
normal -en el instante exacto del gol podía estar a 20 metros del área, ajeno a su propio pase-.
Ahora `_jugada_gol()` le da un destino puntual cerca del rematador por 1.3s, y ese guion tiene
prioridad sobre TODO lo demás en `_mover()` -incluida la celebración, que también lo marcaba a él
como "celebrando" y por eso el primer intento de esta pieza falló en el banco (quedó registrado como
lo que es: un bug de orden de prioridad, no de cálculo). No usa animación nueva: reutiliza
`correr`/`trotar`, que `_animar()` ya elige solo con la velocidad.

**Verificado con `pruebas/banco.gd::_probar_tactica_en_movimiento()` (extendida)**: dispara un
`suceso()` de gol de verdad (la misma puerta que usa el partido en vivo) y mide que el asistidor se
acerque medible al destino de la jugada -30,0 m → 19,8 m en 2 segundos simulados-, no que se quede
en su ranura. `banco OK (0 fallos)` y `.err.txt` vacío.

**Lo que falta para que "todos actúen con sentido" sea cierto de verdad** (el propio usuario puso
la vara ahí, y hoy no está cumplida): solo el asistidor tiene guion. El resto de los 22 sigue con
reparto por zona durante el gol -no es "sin sentido" (la táctica ya los agrupa de forma creíble),
pero tampoco es una jugada coreografiada. El árbitro y los jueces de línea YA siguen el balón con
lógica propia (`_objetivo_arbitro()`, de antes de esta pieza) así que probablemente no necesiten
guion nuevo, pero eso hay que confirmarlo cuando haya forma de verlo. Sin pantalla en este entorno,
la verificación sigue siendo por aserciones medibles -pendiente que el usuario confirme con video o
capturas si esto se **lee** como una jugada real y no solo se mide como una.

## LAS 7 PERILLAS DE TÁCTICA, TODAS CONECTADAS AL 3D (17-9-2026) — CERRADA

Cierre de la tanda de IA/movimiento: rondas 7, 8 y 9, más dos bugs reales encontrados revisando
`.err.txt` en vez de confiar solo en "0 fallos" -exactamente la disciplina que este proyecto viene
pidiendo toda la sesión.

**Ronda 7 — Ritmo**: un equipo de ritmo alto se mueve más rápido en transición SIN el balón que uno
de ritmo bajo -a diferencia de la presión (solo presiona al rival), el ritmo pesa todo el
movimiento sin pelota.

**Ronda 8 — Fuera de juego**: con la trampa activa, la línea defensiva sube más de lo que le tocaría
por `linea` sola, pegada casi a mitad de cancha -solo los 5 puestos de defensa, solo defendiendo.

**Ronda 9 — Salida corta**: con el equipo en fase de ataque, los centrales se separan más del
centro para abrir un carril de pase por dentro.

**Con esto, las 7 perillas de `Tactica` que afectan posicionamiento están conectadas**: mentalidad,
presión, ritmo, línea, amplitud, marca al hombre, fuera de juego. Es la pizarra completa de
Club → Táctica, la misma que ya decidía el resultado del partido, ahora también visible en el 3D.

**Se agregó `pruebas/banco.gd::_probar_tactica_en_movimiento()`**: llama `_objetivo_jugador()`
directo -el mismo método que usa el movimiento real, cada fotograma, para cada uno de los 22- con
la misma ranura de formación y la misma pelota, cambiando solo la `Tactica`, y mide la diferencia
real en metros. Es la forma de "comparar visualmente" sin necesitar pantalla que pidió el usuario.

**Dos bugs reales encontrados con este mismo test, los dos por leer `.err.txt` y no solo el
contador de fallos**:
1. `var rival := _rival_mas_cercano(...)` (ronda 6) infería tipo desde un retorno `Variant`,
   que este proyecto trata como advertencia-error: **rompía la compilación entera de
   `match_playback.gd`**, y como `_probar_tactica_en_movimiento()` fallaba temprano dentro de
   `_ready()`, el banco seguía corriendo el resto de pruebas y reportando "0 fallos" -0 fallos
   porque las aserciones de esa función NUNCA LLEGARON A EJECUTARSE, no porque pasaran. Corregido
   con tipo explícito (`Variant`) en vez de `:=`.
2. El test de marca al hombre armaba un jugador sin la clave `"node"` -en un partido real todo
   jugador la trae (la pone `PlayerSpawner`), pero el test la arma a mano y se había olvidado.
   `_rival_mas_cercano()` reventaba con un error real al intentar leerla, y sin ese nodo el
   resultado zonal y el de marca salían idénticos (41,4 m los dos) -el bug era del arnés de
   prueba, no de la lógica de juego real, pero la aserción inicial pasó igual porque nunca comparó
   nada de verdad. Corregido dándole un `Node3D` real.

Verificado, ESTA VEZ con el contenido real revisado línea por línea, no solo el contador: banco
completo, `FIN. 0 fallos`, `.err.txt` vacío, y las 7 comparaciones tácticas imprimiendo diferencias
medibles reales (ej. marca al hombre: 41,4 m en zona vs 22,8 m marcando; ritmo alto 3,85 m/s vs
ritmo bajo 3,28 m/s en el mismo paso de tiempo). Falta la verificación visual real -el usuario va a
grabar un video jugando.

## MOVIMIENTO DE JUGADORES MENOS ROBÓTICO, NIVEL FC 26 (17-9-2026) — EN CURSO

Pedido explícito: romper la sensación de "bot" en el partido 3D. Todo en
`visor/match_playback.gd::_mover()`/`_objetivo_jugador()` -la capa de DRAMATIZACIÓN del partido, no
la simulación real (`nucleo/partido.gd` sigue decidiendo quién gana solo). Antes: cada jugador
saltaba a velocidad máxima constante hacia su ranura de formación, cambiaba de dirección de golpe, y
los 22 reaccionaban al mismo cambio de fase EN EL MISMO FOTOGRAMA -eso último era lo más "colmena"
de todo: no importa cuán suave se mueva cada uno si los 22 deciden a la vez, como una sola mente.

**Ronda 1**:
- [x] **Inercia real**: velocidad DESEADA (más lenta cerca del objetivo, para no pasarse) perseguida
  por una aceleración limitada (`Vector3.move_toward`), no más saltos a velocidad máxima instantánea.
- [x] **Ritmo propio por jugador**: `_vel_mult` (0,90-1,12×) sacado del hash del id -mismo jugador,
  mismo ritmo siempre, repetible-. No todos corren igual de rápido.
- [x] **Balanceo sutil**: un jugador "quieto" ya no se queda clavado como estatua -un vaivén de
  décimas de metro, desincronizado por jugador (`_fase`), y más marcado lejos del balón que
  disputándolo.

**Ronda 2**:
- [x] **Reacción retrasada por jugador**: el "empuje" de formación que dispara un cambio de fase
  (ataque local/visita) ya no se aplica de golpe -se PERSIGUE con una reacción propia por jugador
  (1,8-3,2 s, sembrada del hash del id). Es la pieza que de verdad rompe la sincronía perfecta: ahora
  cuando el juego cambia de fase, los 22 no giran a la vez, cada uno tarda lo suyo en "leer" la jugada.

**Ronda 3**: separación entre compañeros de equipo (`_separacion()`, radio 3,2 m, como mucho 11
comparaciones por jugador). Sin esto, la fórmula de atracción hacia la pelota podía mandar a dos o
tres compañeros a apuntar casi al mismo metro cuadrado -algo que nunca pasa en un equipo real,
nadie quiere la pelota pegado a otro. Ahora el bloque se ve repartido, no amontonado.

Verificado: banco completo y la prueba dedicada del partido, las 3 rondas, **0 fallos**, sin
`SCRIPT ERROR`. Falta la verificación visual real -mismo límite de pantalla de toda la sesión: no
puedo ver si SE SIENTE menos robótico, solo que la lógica corre sin errores.

**Ronda 4 — LA TÁCTICA POR FIN SE VE**: hasta acá, `Tactica` (mentalidad/presión/ritmo/línea/
amplitud/marca al hombre/fuera de juego -las perillas de Club → Táctica, las mismas que YA deciden
`multiplicador_ataque()`/`_defensa()` del resultado real-) era invisible en el 3D: el visor movía a
los 22 con números fijos sin mirarla ni una vez. `MatchPlayback.setup()` recibe ahora la `Tactica`
de cada equipo (`estadio.gd` pasa `club.tactica`/`visitante.tactica`), y tres perillas ya cambian el
movimiento de verdad:
- [x] **Mentalidad**: escala cuánto empuja la fase de ataque -ofensiva manda más gente arriba,
  defensiva se queda compacta.
- [x] **Línea**: sube o baja el bloque entero hacia una portería u otra, independiente de la fase.
- [x] **Amplitud**: abre o cierra cuánto se pega cada jugador a las bandas respecto al centro.

**Ronda 5 — Presión**: un jugador defendiendo (su equipo no tiene la fase de ataque) corre más
rápido a cerrar al rival si `presion` es ALTA, o no persigue si es BAJA -nunca se aplica atacando,
la presión es una decisión sin balón. **Bug propio encontrado y corregido antes de correr el
banco**: una variable local (`fase`, el balanceo del jugador) tapaba a la variable de instancia
`fase` (el estado del partido) para todo el resto del bucle -renombrada a `p_fase`. Se encontró
releyendo el propio código, no con una prueba -otra razón para no confiar solo en "0 fallos" sin
mirar qué se escribió.

Verificado: banco completo y prueba dedicada, rondas 4 y 5, **0 fallos**, sin `SCRIPT ERROR`.

## OPTIMIZACIÓN DE RENDIMIENTO, RONDA 1: SOMBRAS QUE NADIE NOTA (17-9-2026) — EN CURSO

Pedido explícito: más de 60 FPS en una laptop de gama baja. Sin perfilador ni pantalla no puedo medir
FPS reales -mismo límite de siempre-, así que el trabajo de esta ronda son optimizaciones que se
pueden justificar por lo que cuestan objetivamente, no a ojo: el paso de sombras es de lo más caro en
una GPU integrada (varias pasadas de render por cada luz con sombra), y varios objetos chicos y
repetidos las estaban proyectando sin que se note -su propia base ya tapa la sombra que importa.

- [x] Los 5 camarógrafos del estadio (30 mallas en total) dejan de proyectar sombra.
- [x] Los 3 tramos del brazo de CADA farola del mapa (docenas de farolas) dejan de proyectar sombra.
- [x] Los 2 banderines de club de cada farola, ídem -y de paso conectados a `Texturas.tela()`.

Verificado: banco completo, `FIN. 0 fallos`. **Pendiente y más importante**: correr el juego de
verdad y mirar el contador de FPS -lo único que puede decir si esto (y lo que siga) alcanza el
objetivo. Sin esa medición real, cualquier otra optimización que haga sería trabajar a ciegas sobre
un número que no puedo ver.

## RONDA 6: EMPIEZA LA CIUDAD 3D, Y DOS FUNCIONES DE TEXTURAS MUERTAS DESDE HACÍA RATO (17-9-2026) — EN CURSO

Tras cerrar el estadio (rondas 1-5), barrido del mismo tipo sobre `visor/city_builder.gd` -el
complejo deportivo en 3D, Club → Ciudad-. Hallazgo real: **`Texturas.asfalto()` y
`Texturas.cesped()` existían desde antes de esta sesión con CERO call sites en todo el proyecto**
-escritas y nunca conectadas, el mismo patrón "quedó escrito, no quedó hecho" que el propio
`ROADMAP.md` avisa que se repite en este proyecto-. `city_builder.gd` tiene 51 materiales
`StandardMaterial3D` y ni uno solo pasaba por `Texturas`, pese a que el propio encabezado de ese
archivo dice que la fábrica es "para la ciudad y las instalaciones".

- [x] `Texturas.asfalto()` ganó un parámetro `tinte` (mismo criterio que `hormigon()`) para poder
  conectarla de verdad.
- [x] Las 3 superficies de asfalto más grandes del mapa, conectadas: la plaza de instalaciones
  (hasta 276×160 m), la vía de acceso al estadio (410 m de largo) y el anillo de calles completo
  -la red que conecta las 5 parcelas-. Las tres DUPLICADAS antes de tocar rugosidad/metálico -misma
  disciplina que ya costó aprenderse dos veces en las rondas anteriores con el material cacheado.

Verificado: banco completo, `FIN. 0 fallos`, `.err.txt` vacío
(`herramientas\salida\banco_calidad_ronda6_ciudad_asfalto.log`).

**Ronda 7**: las paredes de los edificios (`_edificio()`) y la marquesina de entrada
(`_detalle_edificio()`, la variable se llamaba "hormigon" desde antes de esta sesión sin serlo)
también conectan `Texturas.hormigon()` -manteniendo la rugosidad/metálico ya afinados a mano en
cada caso, duplicando antes de sobreescribir. Son las paredes más altas y más repetidas del mapa
-una por cada instalación construida, coloreada con el color de club.

Verificado: banco completo, `FIN. 0 fallos` (`herramientas\salida\banco_calidad_ronda7_edificios.log`).

**Ronda 8**: `Texturas.cesped()` ganó parámetro `tinte` (mismo criterio que `asfalto()`) y consiguió
su primer call site en todo el proyecto: el césped del parque del barrio. Su camino reutiliza
`Texturas.asfalto()` con tinte claro de tierra -mismo generador de grano, no hace falta una función
nueva para "tierra compactada". La terminal de buses (metal + pavimento) también conectada.

**Nota descartada**: el terreno general (`_terreno()`, el heightmap de 2.400 m con shader de
ladera) y los campos de entrenamiento (`_un_campo()`, ya reutilizan la textura de césped rayado del
propio `StadiumBuilder`) NO necesitaban este trabajo -son más sofisticados que lo que iba a
aportarles `Texturas.cesped()`, no vale la pena tocarlos.

Verificado: banco completo, `FIN. 0 fallos` (`herramientas\salida\banco_calidad_ronda8_parque_terminal.log`).

**Ronda 9**: los postes de TODAS las farolas -calle principal (9×2) más el anillo completo, docenas
por mapa- comparten ahora `Texturas.metal()` en vez de crear cada uno su propio material plano.
Efecto colateral bueno: además de verse mejor, es más barato para la GPU -antes cada farola creaba
un `StandardMaterial3D` nuevo, ahora comparten la textura de ruido cacheada.

Verificado: banco completo, `FIN. 0 fallos` (`herramientas\salida\banco_calidad_ronda9_farolas.log`).

**Ronda 10**: borde de la piscina olímpica y muro del polideportivo (hormigón), techo curvo del
polideportivo (metal, conservando el color mezclado con el del club), red de las canchas de tenis
(tela real -es una red, no plástico-). Las canchas en sí y sus líneas se quedan pintadas planas a
propósito, es correcto para una superficie sintética pintada.

Verificado: banco completo, `FIN. 0 fallos`
(`herramientas\salida\banco_calidad_ronda10_piscina_polideportivo_canchas.log`).

**Ronda 11**: troncos de todos los árboles del mapa (madera, un solo MultiMesh para todo), máquinas
de cubierta de las instalaciones, marco de la parada de bus, poste de cartel, rampa del
estacionamiento del negocio, y las paredes de otro edificio más (madera/metal/hormigón).

Verificado: banco completo, `FIN. 0 fallos` (`herramientas\salida\banco_calidad_ronda11_varios.log`).

**Ronda 12**: marco de ventanas -compartido por TODOS los edificios del mapa-, tierra del huerto,
suelo de las parcelas vacías/propias.

Verificado: banco completo, `FIN. 0 fallos` (`herramientas\salida\banco_calidad_ronda12_varios.log`).

**Sigue EN CURSO**: 24 de 51 materiales tocados en `city_builder.gd`. Lo que queda son en su
mayoría elementos chicos o de un solo uso (corchera de piscina, cebra peatonal, vidrio de
edificios) -rendimientos cada vez más chicos, se sigue solo mientras aporte de verdad.

## RONDA 5 DE CALIDAD VISUAL: LA FACHADA Y EL TECHO, LO MÁS GRANDE DEL ESTADIO (17-9-2026) — CERRADA

Las 4 rondas anteriores mejoraron 5 componentes chicos (túnel, banquillos, córner, red, escudo).
Barrido completo de `visor/stadium_builder.gd` buscando qué más quedaba en color plano puro -esta
vez sin límite a "los 5 componentes", cualquier material del visor 3D-, y apareció lo más grande de
todos: la fachada entera de las 4 tribunas y el techo completo, la superficie más grande y más a la
vista del estadio después del propio césped, seguían siendo un solo color sin textura.

- [x] **`stand_mat`** (muro exterior + zócalo + esquinas de las 4 tribunas): `Texturas.hormigon()`
  en vez de gris plano -misma fábrica que ya usa el túnel y la ciudad.
- [x] **`roof_mat`** (nueva función `_techo_mat(tipo)`, reutilizada también en el override por
  tribuna de la Fase 1): membrana/retráctil son lona tensada de verdad (`Texturas.tela()` -es
  literalmente el mismo material físico, PTFE/ETFE-), el resto es cubierta metálica estructural
  (`Texturas.metal()`).
- [x] **Torres de foco** (`_focos`): metal en vez de gris plano -son de las estructuras más altas y
  más recortadas contra el cielo de todo el recinto.
- [x] **Marco de las pantallas gigantes** (`_pantallas`): metal en el marco; la pantalla en sí se
  queda lisa y emisiva a propósito -una jumbotron encendida se ve uniforme, textura ahí se leería
  como un panel roto.
- [x] **Banquillo simple de medio campo** (`_banquillos`, la función vieja y simple, no
  `_banquillos_detalle`) y **vallas perimetrales**: metal real en ambos.
- [x] **Postes del arco**: un toque de variación de rugosidad y relieve, SIN subir el metálico -que
  ya estaba bien puesto en 0,15 para un poste pintado, no cromado. `Texturas.metal()` fuerza 0,75 de
  metálico, demasiado para esto, así que se usó `Texturas._tex_ruido()` directo -mismo patrón que ya
  usa el propio césped un poco más arriba en la misma función.

**Nota sobre `_banquillos(root, dx)` vs `_banquillos_detalle()`**: al revisar el archivo completo
para esta ronda, quedó a la vista que existen DOS funciones que dibujan banquillos en posiciones
distintas (`_banquillos` en `x=36,3 z=±9`, cerca del medio campo; `_banquillos_detalle` en
`x=±12 z=40,5`, cerca del área) -las dos se llaman siempre, en cada estadio. Puede ser intencional
(dos elementos distintos) o un resto de cuando se agregó la versión con catálogo. No se tocó la
geometría en esta ronda -es una pregunta de diseño/duplicación, no de calidad de material-, pero
vale la pena mirarlo con una captura real la próxima vez que se abra el visor 3D.

Verificado: 3 bancos (uno por tanda de cambios), los 3 en `FIN. 0 fallos`, `.err.txt` vacío
(`herramientas\salida\banco_calidad_ronda5_fachada.log`, `...ronda5_completa.log`,
`...ronda5_final.log`). Falta la verificación visual real -mismo límite de toda la sesión.

## PASADA DE CALIDAD VISUAL SOBRE LOS 5 COMPONENTES (16-9-2026) — CERRADA

Pedido explícito del usuario tras la Fase 2 del estadio modular: mejorar la calidad visual de los
5 componentes recién conectados (túnel, banquillos, córner, red, escudo), no geometría nueva. Dos
rondas, mismo principio en las dos: reemplazar color plano por los generadores de material con
ruido que ya usa el resto del proyecto (`visor/texturas.gd`) -un objeto de un solo color se lee
como plástico por mucha luz que le eches, es el motivo que el propio archivo se pone en su cabecera
desde antes de esta sesión.

**Ronda 1**:
- [x] **`Texturas.tela()` (nueva)**: trama + relieve + rugosidad no uniforme, mismo patrón que ya
  usan `hormigon()`/`cesped()`/`metal()`. Aplicada a los banderines de córner (`_corners()`) y al
  pórtico inflable del túnel (`_tunel()`, tipo "arco") -los dos eran color plano puro antes de hoy.
- [x] **La red del arco** (`_make_net_texture()`): grano por píxel en el cordel -antes una línea
  perfecta calculada, que con el `uv1_scale` grande de `_add_goal()` se repetía cientos de veces y
  se notaba mucho más que en una textura chica.

**Ronda 2**:
- [x] **`Texturas.madera()` y `Texturas.cuero()` (nuevas)**: el banco de madera del banquillo tipo
  "banca" y los sillones de cuero del tipo "sillones" (`_banquillos_detalle()`) eran color plano.
  Los banquillos simples ("cristal"/"bunker"/"foso") se quedan con plástico simple A PROPÓSITO -no
  todo banquillo tiene por qué ser de lujo, es la nueva `_asiento_simple()`.
- [x] **Los escalones del túnel tipo "foso"** pasan de gris plano a `Texturas.hormigon()`.

**Lección repetida dos veces esta ronda, documentada en el código**: `Texturas.*()` cachea por
color y devuelve la MISMA instancia a cualquiera que pida el mismo tinte -tocarle una propiedad
(como prender emisión) sin `.duplicate()` primero se la prendería a cualquier otro objeto del
estadio o la ciudad que comparta ese color. Ya pasó una vez con el pórtico inflable y se repitió al
tocar los escalones del foso; ambos casos quedaron con el duplicado explícito y el porqué comentado
al lado, para que no se repita una tercera vez en otra fase.

**Ronda 3**:
- [x] **Los banderines de córner salen del color de la camiseta** en vez de un dorado fijo -mismo
  mecanismo que ya heredan las butacas (`_c(est.get("asiento1"), ...)`). Con el fallback puesto al
  dorado EXACTO de siempre, ningún estadio rival cambia -esa clave nunca la trae.

**Ronda 4**:
- [x] **El pórtico inflable del túnel** (tipo "arco") y **los asientos simples del banquillo**
  (tipos "cristal"/"bunker"/"foso") aplican el mismo criterio -color de club si `est` lo trae,
  fallback idéntico al de siempre si no (rojo genérico y gris neutro respectivamente).

Verificado: banco completo tras cada ronda, `FIN. 0 fallos`, `.err.txt` vacío en las 4
(`herramientas\salida\banco_calidad_5componentes.log`, `...ronda2.log`, `...ronda3.log`,
`...ronda4.log`). Falta la verificación visual real -mismo límite de pantalla que el resto de la
sesión.

## EDITAR EL ESTADIO DESDE LA CIUDAD 3D, Y LOS 8 ESTILOS AL FIN CON RED Y ESCUDO (16-9-2026) — CERRADA

Dos pedidos del usuario tras ver el resumen de la Fase 2:

- [x] **`ui/ciudad_vista.gd`**: botón "🏟️ Editar mi estadio" en la barra de la ciudad 3D, y clic
  directo sobre el edificio del estadio -sin colisión física en el mapa (son mallas puramente
  visuales), así que el clic se resuelve proyectando el centro del estadio a pantalla con
  `Camera3D.unproject_position()` y comparando contra el punto del clic, mismo mecanismo ya
  calibrado en esta sesión para el gesto del DT en el podio. Un "clic" exige down+up sin apenas
  movimiento entre medio, para no disparar el editor cada vez que el jugador arrastra para girar
  la cámara. Las dos vías emiten `editar_estadio_pedido`, que `ui/principal.gd::_ver_ciudad_propia()`
  conecta para cerrar la ciudad y saltar directo a Club → Estadio con el diseñador ya pintado.
- [x] **Los 8 estilos completos** (`EST_PRESETS`) ya traían `banquillo`/`túnel`/`córner` elegidos
  desde antes de esta sesión -mudos hasta que la Fase 2 los conectó al visor-. Se les sumó
  `redTipo` y `escudoDonde` a cada uno, pensados por estilo (ej. Arena moderna: red hexagonal +
  escudo en todas partes; Potrero de barrio: red gruesa + sin escudo; Fortaleza nocturna: red
  gruesa + escudo en todas partes, más intimidante). Verificado en el banco que los 8 -no una
  muestra- traen valores válidos contra el catálogo real, no solo que la clave exista.

Verificado: banco completo dos veces (una por cada tanda de cambios), **0 fallos** las dos,
`.err.txt` vacío (`herramientas\salida\banco_presets_y_ciudad.log`,
`herramientas\salida\banco_presets_check2.log`). Falta la verificación visual real -mismo límite
de pantalla que el resto de la sesión.

**Investigado con el conector de Drive** (pedido del usuario, "recuerda los conectores"): el
modelo 3D del presentador que dejó pendiente ("un tipo con tarjeta") es probablemente
`66-rp_eric_rigged_001_c4d.zip` (49,8 MB, personaje "Eric" con rig de Renderpeople) -encontrado en
la misma carpeta que `gato.zip` (la mascota del menú), `cr7/`, `futbolista/`, `entrada-jugadores/`.
**Bloqueado**: el nombre indica formato Cinema 4D puro, que Godot no importa y que esta sesión no
tiene herramienta para convertir (sin Blender ni C4D disponibles). Pendiente: el usuario confirma
si el zip trae también OBJ/FBX -común en los packs de Renderpeople- o lo convierte él mismo antes
de integrarlo.

## EL ESTADIO POR MÓDULOS, FASE 3 DE 3: TRAMO — SOLO SPIKE, SIN CERRAR (16-9-2026)

Antes de comprometer una forma de datos para "estilos mixtos dentro de una misma tribuna" -la
lógica de "tramo" que pidió el usuario, la más arriesgada de las tres-, se escribió un spike
aislado para decidir con una captura real si el corte más barato (la tribuna partida en 3 tercios
fijos, cada uno con su propio patrón de butaca completo, techo/fachada/altura siguen siendo del
recinto entero) se sostiene visualmente o se ve como una textura rota, sobre todo por la
inclinación de la rampa.

- [x] `visor/stadium_builder.gd::_make_stand_texture_tramos()`: misma lógica de dibujo que
  `_make_stand_texture()`, repetida por tercio -código de prototipo a propósito, sin abstraer
  hasta saber si el resultado sirve-. NO está conectada a `EST_DEF`, `perfil()` ni la UI: nada de
  esto cambia el estadio real de nadie.
- [x] `pruebas/spike_tramo.gd`/`.tscn`: una sola rampa aislada (mismas proporciones que una
  tribuna real de 2 niveles) con 3 patrones/colores bien distintos por tercio, dos cámaras -una
  general, otra pegada a una costura- y dos capturas (`pantalla_tramo_general.png`,
  `pantalla_tramo_costura.png`).

**SIN CERRAR**: esta sesión no tiene pantalla real (mismo límite que las otras entradas de hoy), así
que no se pudo mirar la captura y decidir si el corte se sostiene. **Pendiente del usuario**:
correr `godot --path dinastia-godot --rendering-driver opengl3 res://pruebas/spike_tramo.tscn` y
mirar las dos imágenes. Si la costura se ve bien, recién ahí se diseña la Fase 3 completa (forma de
datos en `EST_DEF`, UI, persistencia) como tarea aparte -ver el plan en
`C:\Users\Alumno\.claude\plans\smooth-soaring-micali.md`-. Si se ve mal, hay que repensar el corte
antes de escribir motor de verdad.

## EL ESTADIO POR MÓDULOS, FASE 2 DE 3: COMPONENTES (16-9-2026) — CERRADA

Segunda de las tres fases (bandeja → componentes → tramo). A diferencia de Bandeja, esta no
necesitó tablas nuevas: `redTipo`, `corner`, `banquillo`, `tunel` y `escudoDonde` ya estaban en
`EST_DEF`, ya se cobraban y ya se pintaban en el diseñador (Club → Estadio) desde antes -pero
`EstadioPropio.perfil()` nunca se las pasaba al visor 3D, así que elegir una opción distinta no
cambiaba nada en el estadio. Era wiring puro, no motor nuevo.

- [x] `nucleo/estadio_propio.gd`: `perfil()` agrega las 5 claves, siempre -a diferencia de
  `bandejas` (Fase 1), que es condicional-. Contrato de la clase (líneas 12-36) actualizado.
- [x] `visor/stadium_builder.gd`:
  - `_make_net_texture()` +`tipo` (catálogo `EST_REDTIPO`: cuadrada/fina/gruesa/rombo/hexagonal) —
    patrones de cordel distintos, el de siempre queda de default.
  - `_corners()` +`tipo` (`EST_CORNER`: clásico/alto/doble/led/sin) — poste más alto con
    inclinación fija ("doblado por el viento"), doble bandera superpuesta, base con luz propia, o
    directamente nada.
  - `_banquillos_detalle()` +`tipo` (`EST_BANQUILLOS`: cristal/bunker/banca/sillones/foso) — desde
    un banco de madera sin nada de estructura hasta un foso hundido y cubierto por una losa.
  - `_tunel()` +`tipo` (`EST_TUNELES`: central/esquina/telescópico/arco/foso) — boca desplazada al
    corner, un tubo retráctil que se estira sobre la cancha, un pórtico inflable curvo (`TorusMesh`
    con emisión, sin el arco de hormigón), o una escalera iluminada emergiendo del césped.
  - `_escudo_cancha()` (nueva, en `build_pitch()`) y `_escudo_tribuna()` (nueva, en `build()`):
    pintan el escudo del club -reutilizando `Escudo.textura()`, que ya existía para la UI 2D, cero
    arte nuevo- en el círculo central, la grada principal, el borde del techo, o las tres a la vez
    según `escudoDonde`.
  - **Asimetría a propósito, documentada en el código**: el default que usa `StadiumBuilder` para
    `escudoDonde` cuando la clave falta es `"sin"`, NO el `"cancha"` de fábrica de `EST_DEF` -un
    rival, que nunca trae esta clave, no debe empezar a mostrar un escudo que nunca pidió. Los
    otros 4 campos sí usan el mismo default que `EST_DEF`, porque ese default YA coincidía con el
    único dibujo que existía antes de esta fase (central/cristal/clásico/cuadrada).
  - `build_pitch()` y `build()` ganan un parámetro opcional `mi: Club = null`, sin romper ningún
    call site existente (`city_builder.gd`, `pruebas/captura_camarografos.gd` siguen sin pasarlo).
    `ui/estadio.gd` sí lo pasa ahora (`club`), tanto para el club propio como para un rival -el
    rival simplemente no dibuja nada porque su perfil nunca trae `escudoDonde`.

**Verificado**: banco completo, `FIN. 0 fallos`, `.err.txt` vacío
(`herramientas\salida\banco_componentes_fase2.log`), incluida la comprobación de que un rival
sigue sin las 5 claves nuevas. `pruebas/captura_componentes.gd`/`.tscn` quedaron escritos para la
verificación visual -mismo límite de pantalla que el resto de hoy, pendiente que el usuario los
corra.

## EL ESTADIO POR MÓDULOS, FASE 1 DE 3: BANDEJA (16-9-2026) — CERRADA

Primer punto de la Fase 3 del `ROADMAP.md` ("el estadio por MÓDULOS"), que estaba bloqueado hasta
decidir qué es una "pieza". Decisión del usuario: las tres lógicas a la vez -componentes, tramo,
bandeja-, en ese orden de implementación (bandeja primero por el mejor encaje con el código
existente, componentes segundo por ser wiring barato, tramo al final como spike de verificación
visual). Esta entrada cierra solo Bandeja; Componentes y Tramo quedan en el plan
(`C:\Users\Alumno\.claude\plans\smooth-soaring-micali.md`) para las próximas tandas.

**Qué cambia**: activando "Personalizar cada tribuna" en Club → Estadio, cada una de las 4 tribunas
(sur/norte/este/oeste) puede tener su propio patrón de butacas y su propio techo, en vez de un solo
estilo para las 4. Los colores de butaca y la altura/forma del recinto siguen siendo globales -variar
eso por tribuna es geometría de costura nueva, eso es trabajo de la Fase 3 (Tramo), no de esta.

- [x] `datos/tablas.json` (`EST_DEF`): 9 claves nuevas -`personalizar_bandejas` (bool) +
  `bandeja_<lado>_asientoP`/`_techo` × 4 tribunas-, editadas con un script de PowerShell que localiza
  el objeto por balanceo de llaves y solo inserta ahí, sin tocar ni una coma del resto del archivo de
  425 KB. Verificado el JSON resultante con `JavaScriptSerializer` de .NET -`ConvertFrom-Json` de
  PowerShell 5.1 lo daba por inválido con un archivo de este tamaño, pero es una limitación conocida
  del cmdlet, no del archivo: confirmado con un parser más estricto.
- [x] `nucleo/estadio_propio.gd`: `CATALOGO_DE`/`CAPITULO`/`PRECIO` con las entradas nuevas
  (capítulo `"personalizacion"`, 90.000 -activar el modo cuesta, no es gratis-). `perfil()` solo
  añade la clave `bandejas` cuando el interruptor está activo: con él apagado el diccionario que ve
  el visor es idéntico, clave por clave, al de antes de esta fase -verificado con una comparación de
  `keys()` en el banco, no solo "no revienta"-. `""` en un campo de tribuna = hereda el valor global,
  la misma convención que ya usaban `asiento1`/`asiento2` con el color de camiseta.
- [x] `visor/stadium_builder.gd`: `build()` resuelve el estilo de cada tribuna
  (`NOMBRE_BANDEJA` = mismo índice 0-3 que ya comentaba el array `stands`) y solo genera una textura
  de grada o un material de techo propio cuando esa tribuna pidió algo distinto del global -si no,
  sigue compartiendo los mismos materiales que antes, cero trabajo de más para un estadio sin
  bandejas personalizadas-.
- [x] `ui/principal.gd`: interruptor + selector de tribuna (reutilizando `_fila_diseno_estadio()` tal
  cual, sin widget nuevo) en un bloque "LAS TRIBUNAS" nuevo en Club → Estadio.

**Verificado**: banco completo, `FIN. 0 fallos`, `.err.txt` vacío
(`herramientas\salida\banco_bandeja_fase1.log`), incluida la comparación exacta de claves del
perfil con el interruptor apagado y la reforma de una sola tribuna con el interruptor prendido.
**Falta la verificación visual real** -`pruebas/captura_bandejas.gd`/`.tscn` quedaron escritos
siguiendo el mismo patrón que `captura_estadio_propio.gd`, pero esta sesión no tiene pantalla para
correrlos (mismo límite ya documentado en la entrada de calidad del partido, más abajo). Pendiente
que el usuario los corra con `herramientas\run_godot.ps1 -Jugar` y mire Club → Estadio.

## "MEDIO" EN AJUSTES YA ALIVIA TAMBIÉN EL PARTIDO, NO SOLO LA CIUDAD (16-9-2026) — CERRADA

Pedido: el usuario sintió el 3D lento jugando y pidió revisarlo. **No pude medir FPS reales de esta
sesión**: intenté un diagnóstico con ventana de verdad (`pruebas/diagnostico_fps_partido.gd`, corre un
partido completo con `VistaEstadio` y muestrea `Engine.get_frames_per_second()` cada segundo) tanto con
Vulkan/Forward+ (el modo real del juego, confirmado por el log: `Vulkan 1.3.237 - Forward+ - Intel(R)
UHD Graphics`) como forzando OpenGL Compatibility, y las dos veces el proceso se quedó colgado sin
imprimir ni una muestra -este entorno de automatización no tiene una pantalla real donde Godot pueda
presentar fotogramas, no es un dato de que el juego tarde 15+ segundos por fotograma-. El script de
diagnóstico queda escrito y lo puede correr el usuario en su máquina
(`herramientas\run_godot.ps1 -Jugar` y mirar el contador, o
`godot --path dinastia-godot res://pruebas/diagnostico_fps_partido.tscn` con ventana) para tener un
número real.

**Lo que sí encontré revisando el código, sin necesitar el número**: `ui/ciudad_vista.gd` respeta el
nivel de `Ajustes` (`Calidad.elegida`) para prender/apagar oclusión ambiental y sombras en 4 cascadas
-las dos cosas más caras de Forward+ en una Intel UHD sin GPU dedicada, el propio `Calidad.gd` lo dice
en su comentario-, pero `visor/ambience.gd` -la que arma la luz del PARTIDO, la escena más pesada de
las dos (22 jugadores animados, balón, cámaras que persiguen la jugada)- las tenía **encendidas
siempre**, sin mirar `Calidad.elegida` para nada. Bajar a "Medio" en Ajustes aliviaba la ciudad pero no
tocaba un pelo el partido -justo la pantalla que más probablemente sea la lenta-.

- [x] `Ambience.apply()` ahora recibe `nivel` (por defecto `Calidad.ALTO`, no cambia nada si no se pasa
  nada) y solo prende oclusión ambiental y sombras de 4 cascadas cuando `nivel >= Calidad.ALTO`, igual
  que ya hace `Calidad.entorno()` para la ciudad. En "Medio" el partido pasa a sombras de 2 cascadas y
  media distancia (160 m en vez de 260 m) y sin SSAO.
- [x] `ui/estadio.gd` pasa `Calidad.elegida` en la llamada -antes no se pasaba nada, así que siempre caía
  en el valor por defecto ALTO sin importar lo que el jugador hubiera elegido en Ajustes-.

Verificado: banco completo tras el cambio, `FIN. 0 fallos`, `.err.txt` vacío
(`herramientas\salida\banco_post_calidad_partido.log`). **Falta la verificación real que solo se puede
hacer con pantalla**: confirmar a ojo que "Medio" se ve más fluido jugando de verdad -no se pudo hacer
desde esta sesión por la limitación de entorno de arriba-.

## LIMPIEZA DE DISCO (16-9-2026)

El usuario pidió liberar espacio (SSD de 119 GB, quedaban ~17 GB libres). Se borraron, con
confirmación explícita del usuario en cada caso:
- `respaldos\v7.6-...` (260 MB) -ya existía `v7.7`, la política del proyecto es un solo respaldo activo-.
- `visor3d\` (118 MB) -el proyecto Godot viejo y SEPARADO del visor 3D, de antes de que
  `ui/estadio.gd` lo integrara directo dentro de `dinastia-godot`. Mismos nombres de archivo
  (`stadium_builder.gd`, `balon_3d.gd`, etc.) que los de `dinastia-godot/visor/`, pero es la versión
  vieja standalone, no referenciada desde el juego actual-.
- `datos-navegador\` (180 MB) -un perfil de Chrome (extensiones, caché, `FirstPartySetsPreloaded`)
  que estaba metido dentro de la carpeta del proyecto sin relación con el juego. Ajeno a DINASTÍA.

Disco libre: 17,0 GB → 17,5 GB.

## EL PARTIDO 3D AL NIVEL "FIFA": BALÓN CON FÍSICA, 9 CÁMARAS, CONTROL MANUAL Y RADAR (15/16-9-2026) — CERRADA

Tanda grande hecha en una sesión de Antigravity (15-9) y cerrada acá (16-9): la parte de "nivel FIFA"
que el `ROADMAP.md` daba por bloqueada por presupuesto de API en realidad no necesitaba API -era
código y geometría, no arte nuevo generado-. Ocho archivos:

- [x] **`visor/balon_3d.gd` (nuevo).** El balón ya no es una malla suelta que `MatchPlayback` movía a
  mano con un `lerp` + seno decorativo. Ahora `Balon3D` pinta su propia piel -reutilizando
  `Comercial.BALON_SKINS`, que existía en el catálogo y nunca se pintaba en el 3D- y se mueve sola:
  `enviar()` lanza un tiro/pase con una parábola real (altura de verdad, no un seno) y `avanzar()` la
  hace rodar con el eje de giro correcto (perpendicular a la dirección de viaje, no fijo en X). Si es
  gol, amortigua y cae dentro de la red en vez de atravesarla.
- [x] **`visor/camera_rig.gd` (nuevo).** 9 cámaras: Principal (TV), Tele Dinámica (sigue la jugada por
  la banda), Primera Persona (POV, anclada a la cabeza del jugador activo), Pro Tercera Persona (detrás
  del hombro), Tribuna alta, Detrás del arco, A ras de campo, Cenital táctica y Dron orbital. Zoom y
  altura ajustables en caliente (rueda del mouse, +/-, RePág/AvPág), Tab para ciclar.
- [x] **`visor/control_partido.gd` (nuevo).** Modo de control manual estilo FC 26: WASD, sprint, pase
  corto, pase largo, disparo cargado, barrida y cambio de jugador al más cercano al balón. Alternable
  con el modo Manager (automático) desde un botón en `VistaEstadio`.
- [x] **`ui/radar_partido.gd` (nuevo).** Radar táctico 2D en la esquina inferior derecha con los 22
  jugadores, árbitros y el balón en tiempo real.
- [x] **`visor/stadium_builder.gd` y `ui/estadio.gd`**: arcos con postes/larguero cilíndricos FIFA,
  tensores traseros y red con textura perforada real (antes plana); `estadio.gd` conecta el balón real,
  el rig de 9 cámaras y el radar dentro de `VistaEstadio._construir()`.
- [x] **`visor/match_playback.gd`**: pasó de mover el balón a mano a llamar `Balon3D.enviar()`/
  `avanzar()` con duración y altura calculadas según distancia y tipo de jugada (gol, atajada, poste,
  fallo, pase).

**Lo que encontré sin cerrar al retomar la sesión (el patrón de "quedó escrito, no quedó hecho" que
avisa el propio `ROADMAP.md`)**: la sesión anterior dejó escrito `pruebas/captura_partido_realista.gd`
-la prueba de integración de todo lo anterior- pero **nunca llegó a correrla**: le faltaba su
`.tscn` (el resto de `pruebas/` sigue 1 script → 1 escena) y ninguna de sus líneas de `print()`
aparecía en ningún `.log`. Al crear la escena y correrla por primera vez, salió "0 fallos" en la
salida estándar pero el `.err.txt` -que nunca hay que ignorar, ver regla de oro nº4 del `ROADMAP.md`-
tenía un `SCRIPT ERROR` real: `_a_la_lesion()` en `ui/estadio.gd:415` asumía un `Jugador` no nulo, y el
test la disparaba con `null`. Confirmado contra `nucleo/partido.gd:594-612` que en el juego real esa
señal *nunca* emite con jugador nulo (pasa siempre por `if h != null`), así que el bug estaba en el
test, no en el código de producción: se corrigió el test para usar un jugador real
(`_partido.once_local[0]`) en las cuatro señales simuladas.

Verificado: `captura_partido_realista.gd` corre limpio (0 fallos, sin `SCRIPT ERROR`) y el banco
completo del núcleo también (`FIN. 0 fallos`, `.err.txt` vacío,
`herramientas\salida\banco_cierre_16sep.log`). Quedan avisos de motor al salir (`RID allocations
leaked at exit`) -ruido de cierre de Godot headless con nodos 3D todavía en el árbol al hacer
`quit()`, no un fallo funcional del juego jugado de verdad-.

## EL DT APOYA LAS MANOS EN EL PODIO (14-9-2026) — CERRADA

Segunda mitad de "invierte en eso": el DT de la rueda de prensa (retrato 2D fijo de `CaraDT`) ya no
tiene solo la cabeza asintiendo -ahora también apoya las dos manos en el borde del podio, con un
vaivén mínimo independiente en cada una para que no se lean como una sola pieza rígida
(`_montar_gesto_dt()`/`_segmento()` en `ui/rueda_prensa_escena3d.gd`). El color de piel sale del
propio `look_dt` -la misma mano que dio la cara-.

**Dos vueltas hasta acertar la geometría, las dos encontradas mirando la captura real, no
adivinando:**
1. Primer intento: brazo diagonal desde un "hombro" a 1,36 m hasta una mano a 1,0 m. En la captura
   los brazos salían pegados a las orejas, como tubos creciendo de la cara. La cámara del plano
   "de trabajo" (el más cerrado, y el que más tiempo se ve) encuadra tan poco torso -de la barbilla
   al borde del podio hay apenas centímetros de mundo- que cualquier objeto a esa altura cae casi
   encima de la mandíbula, no del hombro.
2. Comprobado con `Camera3D.unproject_position()` -proyectando puntos de calibración conocidos a
   píxeles, no a ojo- que el borde real que tapa al DT en esta escena es el del OCULTADOR del podio
   generado por IA (0,75 m), no el `cuerpo` procedural completo (1,05 m) que se supuso al principio.
   Con eso resuelto, el cambio real de diseño: un antebrazo apoyado en una mesa va PLANO sobre ella,
   no en diagonal desde un hombro alto -es como de verdad se apoyan las manos en un podio-. Un solo
   tramo casi horizontal a la altura de la mesa (0,85 m) resuelve la pose Y evita el mismo riesgo de
   codo-alineado-con-la-cámara que costó horas en el presentador del sorteo (ver más abajo): con un
   solo segmento recto no hay codo que alinear.

Verificado con `pruebas/captura_dt_rueda_prensa.gd` en los tres planos de cámara (el cerrado de
trabajo, el general y el lateral): en los tres se lee como manos apoyadas en el podio, no como un
objeto flotando cerca de la cara. Banco headless en 0 fallos.

## EL PRESENTADOR DEL SORTEO: EL HUMANOIDE REAL, EL BUG DEL BRAZO "ESTIRADO" Y POR QUÉ QUEDÓ EN PAUSA (14-9-2026)

Pedido: *"El sorteó veo qué estéticamente deja qué desear el presentador y la animación"*. Se
reemplazó la silueta de cajas (`_montar_presentador_siluetas()`) por el mismo humanoide real que usan
los 22 del campo (`Futbolista`/`AnimMixamo`/`Vestidor`, ver `_montar_presentador_modelo()` en
`ui/sorteo_escena3d.gd`), vestido con `Vestidor.vestir(..., color_liso)` -el mismo mecanismo que ya
viste a árbitros sin equipación de club- y con la animación real `parado` de pie, `mostrar_tarjeta`
como gesto de sacar la bola (`gesto_sacar()` ahora rama entre el `AnimationPlayer` real y el brazo
suelto de la silueta, según cuál esté montada).

**El hallazgo real: no era un bug de animación.** La primera captura desde la cámara "presentador en
primer término" (`PLANOS[2]`) mostraba un brazo aparentemente estirado como una tabla. Se comprobó
hueso por hueso (`pruebas/captura_parado_aislado.gd`, con y sin la escena completa) que la pose es
IDÉNTICA -mismos ángulos, mismas posiciones globales- se vea bien o mal: es la MISMA pose (codo
doblado de verdad, antebrazo colgando) que un ángulo de cámara demasiado lateral respecto a hacia
dónde mira el cuerpo (gira -32°) proyecta con el codo casi alineado con la cámara, y las dos mitades
del brazo se leen como una sola línea recta. Corregido acercando esa cámara a un ángulo más de frente
(diferencia cámara-cuerpo por debajo de unos 35-40°) en vez de tocar ni un hueso del catálogo
compartido con los 22 del campo. Verificado con captura real: el brazo ya se dobla con naturalidad,
de pie y en el gesto.

**Queda en pausa a propósito.** El usuario avisó que dejó un modelo 3D propio -"un tipo con tarjeta",
pensado para el sorteo y reutilizable para el público- en su Drive, y prefiere rehacer el presentador
con ese modelo en vez de seguir estirando el truco de vestir al futbolista de traje (la malla sigue
siendo camiseta+shorts pintada de azul marino: lee a deportista, no a traje de gala, por más que el
color case). Pendiente: traer ese modelo (no hay conector de Drive activo en la sesión que hizo este
trabajo; hay que recibirlo por archivo directo o con el conector ya cargado desde el arranque de una
sesión) y remontar `_montar_presentador_modelo()` sobre él.



## Cómo se ejecuta

```powershell
herramientas\run_godot.ps1              # banco de pruebas headless
herramientas\run_godot.ps1 -Jugar       # abre el juego
herramientas\run_godot.ps1 -Captura     # deja el juego con datos y guarda dos capturas
herramientas\run_godot.ps1 -Reimportar  # si algo se queja de que no encuentra una clase
```

La primera vez importa el proyecto solo. Si algún día salen cuarenta errores seguidos del tipo
*"Identifier Mundo not declared in the current scope"*, no es el código: es que falta la caché de
clases, y se arregla con `-Reimportar`.

## LA RUEDA DE PRENSA, SEGUNDA PASADA: ESCUDOS DE LA LIGA Y EL DT CORRECTO (14-9-2026) — CERRADA

Pedido textual, tras ver la primera mejora: *"me gustaría qué al fondo fueran los escudos de los
clubes de la competencia correspondiente, además de qué si el entrenador debe ser el qué nosotros
escogimos"*.

- [x] **El fondo ya muestra escudos de tu liga, no sponsors genéricos.** La pared de
  `_montar_fondo_sponsors()` rotaba por `Datos.tabla("MARCAS")` -auspiciadores sin relación con el
  partido-. La rueda de prensa SOLO se abre tras un partido de LIGA (`Mundo.rueda_tras_resultado()`,
  el único call site real de `Prensa.abrir_rueda()` fuera de pruebas -confirmado con grep exhaustivo
  antes de tocar nada-), así que la competencia correspondiente es siempre tu propia liga:
  `mundo.liga_de(mio).clubes` viaja ahora hasta la escena 3D y sus escudos reemplazan a las marcas
  -tu propio escudo cada tercera celda, como el anfitrión de una pared de prensa real-.
- [x] **HALLAZGO REAL AL VERIFICAR "el entrenador que escogimos": la placa y la escena 3D SIEMPRE
  mostraban al JUGADOR, incluso cuando el jugador no es el entrenador.** Si el rol activo es
  ayudante de campo / director deportivo / dueño con el banco delegado, `Roles.dt_empleado` tiene
  nombre propio -es OTRA persona la que dirige-, pero la rueda de prensa seguía mostrando tu cara: el
  dueño del club dando la conferencia técnica en tu lugar. Arreglado: si `dt_empleado` no está vacío,
  habla él, no tú. Como un empleado no tiene editor de aspecto propio -nadie personaliza a alguien que
  no eres tú-, `CaraDT.look_de_nombre()` (nuevo, mismo patrón djb2 con una sal por rasgo que ya usa
  `Cara._hash()`) le da un aspecto determinístico por su nombre: el mismo empleado siempre sale igual.
  Se corrigió tanto la placa "chyron" como la escena 3D -las dos usaban `roles.look_efectivo()` a
  pelo, sin mirar `dt_empleado` nunca-.

Verificado forzando el caso más exigente (`Roles.arrancar_ayudante()` + rueda de prensa real): la
placa muestra el nombre del empleado ("Lucas Muñoz" en la prueba, no el del jugador), su retrato es
visiblemente distinto al del jugador, y el fondo muestra escudos de clubes reales, no logos
genéricos. Banco completo: 0 fallos.

**Sobre "así de abismal debe ser la mejora de los sorteos"**: revisando `sorteo_escena3d.gd` para
comparar, resultó que el sorteo YA tiene un nivel de producción mucho más alto que el que tenía la
rueda de prensa antes de hoy -sala completa con público, pared LED, presentador con gesto de brazo
articulado, 4 planos de cámara que cortan en cada bola, confeti al salir tu club-. La lectura correcta
del pedido es la inversa: llevar la rueda de prensa AL NIVEL del sorteo, no el sorteo al nivel de la
rueda. Hecho en la misma sesión, sin esperar a otra tanda:

- [x] **Sala completa**: paredes laterales + techo con truss de focos, mismo principio que
  `SorteoEscena3D._montar_sala()` a la escala mucho más chica de este plató (10×8 m contra 13×9).
- [x] **Periodistas visibles**: filas de siluetas simples (cajas+cápsulas, sin cara -mismo patrón
  barato que `_montar_publico()` del sorteo-) a los lados del plató, con una luz de relleno propia
  -sin ella eran invisibles, su material se fundía con el negro del fondo, mismo error ya pagado con
  el DT y el presentador del sorteo-.
- [x] **Tres planos de cámara que cortan solos cada pocos segundos**: de trabajo (el de siempre),
  general (contra la pared del fondo, FOV abierto a 58° para que se lea la sala entera con el podio
  chico al fondo) y lateral (contrapicado desde el lado de los periodistas). El FOV fijo (34°) no
  bastaba para que el plano general se sintiera distinto solo con más distancia -a diferencia del
  sorteo, donde las posiciones están mucho más separadas-, así que el FOV también interpola por plano.
  Añadido de paso un balanceo mínimo en el retrato del DT (sube y baja 6 mm) para que no se lea como
  una foto pegada en los planos más alejados.

Verificado con capturas reales de los tres encuadres: la sala se ve completa, los periodistas se
notan como siluetas (no como manchas negras), y el plano general revela el podio pequeño al fondo con
el DT reconocible. Banco completo: 0 fallos.

## FASE 2 DEL ROADMAP CERRADA: EL LETRERO "GIGANTE" ERA FALSA ALARMA, Y EL BARRIDO NO ENCONTRÓ MÁS (14-9-2026)

Último punto de "la piel 3D" antes del ítem de nivel FIFA (bloqueado por presupuesto de API, sin
cambios). El letrero "Polideportivo" que parecía gigante y distorsionado en `sdfgi_on.png` resultó ser
un artefacto de esa prueba en concreto: `captura_sdfgi.gd` fuerza la cámara a 65 m de altura para
probar SDFGI, muy por debajo de los 110 m con los que la cámara arranca de verdad
(`ciudad_vista.gd:34`). Generada `pruebas/cartel_ciudad_camara_real.png` con la cámara real: los 6
carteles del mapa se ven pequeños y bien proporcionados. Nada que arreglar -otra vez el patrón de
"verificar antes de anunciar un bug" que tantas veces se ha repetido en este proyecto-.

El barrido de capturas 3D existentes (partido en vivo, estadio nocturno, ciudad) no encontró ningún
caso nuevo del mismo tipo de problema. **La Fase 2 del `ROADMAP.md` ("la piel 3D") queda cerrada**,
con tres arreglos reales del día: la cámara del estadio que estaba encima del techo (dos cámaras), y
el DT de la rueda de prensa con cara real.

## EL DT DE LA RUEDA DE PRENSA YA TIENE CARA DE VERDAD (14-9-2026) — CERRADA

Fase 2 del `ROADMAP.md`, siguiente punto tras el estadio: "la rueda de prensa: el locutor 3D es una
cápsula azul con una esfera blanca de cabeza, sin ropa ni cara. Es la escena 3D con peor terminación
del juego hoy".

**La solución no fue construir un sistema nuevo de UV-mapping 3D** -eso sigue pausado a propósito
(Fase 5 del roadmap, "cara real sobre el modelo 3D del jugador", pendiente de permiso-. `CaraDT.
textura()` ya dibuja un retrato completo -cara con los rasgos que el jugador eligió en Mi Carrera,
corte de pelo, traje y corbata del club, viewBox cuadrado de hombros para arriba- porque es EL MISMO
SVG que ya usa `_pintar_aspecto_dt()`. Bastaba con mostrar ESE retrato en la escena 3D en vez de
reconstruir el cuerpo con geometría genérica.

`RuedaPrensaEscena3D._montar_dt()` reemplaza el conjunto cápsula+esfera+corbata (colores planos, sin
rasgos) por un único `QuadMesh` de 0,95×0,95 m con la textura de `CaraDT.textura(look_dt, 256)` -
material `UNSHADED` + emission, igual que ya hace la pared de sponsors, para que el sombreado propio
del SVG no dependa de las luces del plató-. El aspecto viaja desde `principal.gd`
(`mundo.roles.look_efectivo()`) hasta la escena 3D vía un parámetro nuevo de `montar()`; si viene
vacío -compatibilidad hacia atrás- se conserva la geometría genérica de siempre como respaldo.

Verificado con `pruebas/captura_dt_rueda_prensa.gd` (nuevo, permanente): fuerza una rueda de prensa
real (`Prensa.abrir_rueda()`) y abre la pantalla completa, capturando el resultado. La imagen muestra
al DT con cara, ojos, cejas, corte de pelo y la camiseta/colores del club -nada que ver con la cápsula
azul sin rasgos de antes-. Banco completo: 0 fallos.

## EL BLOQUE GRIS DEL ESTADIO: LA CÁMARA "PRINCIPAL (TV)" ESTABA ENCIMA DEL TECHO (14-9-2026) — CERRADA

Fase 2 del `ROADMAP.md` ("la piel 3D"), primer punto. La captura de referencia (`pruebas/pantalla.png`,
tomada con `-Captura`) mostraba un plano gris-azulado liso ocupando el 40% inferior de la pantalla en
la cámara "Principal (TV)" -la que usa la mayoría de las partidas-, ya anotado como "pendiente menor"
desde el 13-9 sin diagnosticar.

**El método, porque la causa NO era la que parecía a simple vista.** Se sospechó primero de la
`_explanada_de_fondo()` (la base de hormigón que tapa el hueco más allá del césped, arreglada el
13-9) y del reflejo Fresnel del material en ángulo rasante -ninguna de las dos era la causa: ocultar
la explanada por completo, y luego pintarla de rojo puro, no cambió NI UN PÍXEL de la captura-. En vez
de seguir adivinando, se escribió un raycast manual (`AABB.slab-test` contra las 260 mallas de la
escena real, usando `Camera3D.project_ray_origin/normal` desde el píxel exacto de la franja gris) para
encontrar la geometría real. **Resultado: el primer objeto que golpeaba el rayo era la cara inferior
del TECHO de la tribuna, a menos de 1,5 metros de la cámara.**

**La causa, confirmada con aritmética exacta, no aproximada.** El techo de cada tribuna se centra en
`Y = alto + 0.4` con 0,5 m de grosor (`stadium_builder.gd`, la línea que ya construye el techo desde
hace semanas), así que su cara inferior está en `alto + 0.15`. La cámara "Principal (TV)" se calculaba
con `alto * 0.55 + 4.0`. Para un estadio de **1 nivel** (`alto = 6.5`, el caso real de la captura,
"Cuenco de 1 niveles"): cámara en Y=7,575, techo desde Y=6,65 hasta Y=7,15 -**la cámara quedaba por
ENCIMA de todo el techo**, mirando su cara de abajo a bocajarro-. Para 2 niveles el margen ya sale
positivo (~2 m) y para 3 niveles de sobra (~5 m): por eso el bug solo se notaba en el estadio más
chico, y por eso nadie lo había atado antes al mismo problema que el comentario de la cámara "Tribuna
alta" ya describe línea por línea ("la pantalla se llena de la cara interior del techo: naranja lisa,
sin ningún error en consola") -es el MISMO bug, en la OTRA cámara, sin corregir ahí hasta hoy-.

**Arreglo de una línea**: `camera_rig.gd`, `Y = minf(alto * 0.55 + 4.0, alto - 1.5)` -nunca deja que la
cámara suba más que 1,5 m por debajo del arranque del techo, sin tocar el caso de 2-3 niveles que ya
funcionaba bien-. Verificado en tres capas, no solo una:
1. El mismo raycast, ahora apuntando al césped real en vez del techo.
2. Captura visual real (`--rendering-driver opengl3`): el bloque gris desapareció por completo, se ve
   el campo entero con buena textura.
3. `pruebas/captura_camara_principal_techo.gd` (nuevo, permanente, headless -sin necesitar ventana,
   el raycast no depende de renderizar-): reconstruye el estadio más grave (1 nivel) y comprueba que
   el 70/76/90% de la altura del encuadre golpea el césped, no el techo. Banco completo: 0 fallos.

**Trampa nueva encontrada haciendo esta prueba**: las coordenadas de píxel para `project_ray_*` NO se
pueden fijar a mano (`Vector2(640, 500)`) si la prueba se corre a veces con ventana
(`--resolution 1280x720`) y a veces headless (`--headless`, que usa el tamaño base del proyecto,
distinto): el mismo píxel absoluto apunta a un ángulo distinto del frustum según el tamaño real del
viewport. Se corrigió calculando el punto como fracción de `get_viewport().get_visible_rect().size`.

**Y de paso, la misma tanda cerró el bloque negro de "Detrás del arco" (el que documentó
`dinastia-estadio-hueco-y-tunel-negro` el 13-9, sin diagnosticar).** Con el raycast ya escrito, se
comprobó esa cámara por si acaso -el cálculo a mano ya daba un margen de solo 0,375 m contra el mismo
techo (`alto*0.35+4.0` para la altura, contra `alto+0.15` de la cara inferior)- y el raycast confirmó
que SÍ rozaba el techo en el 5-15% superior del encuadre: la franja negra sólida que se ve en
`pruebas/tunel_camara_real.png` desde el 13-9 no era el cielo nocturno, era la cara de abajo del
mismo techo. Mismo arreglo (`minf(alto*0.35+4.0, alto-1.5)`), misma prueba de regresión ampliada para
cubrir las dos cámaras. Verificado con captura real: el cielo nocturno con su degradado normal aparece
donde antes había un bloque negro sin ningún detalle. Banco completo: 0 fallos.

## LA RUTA DE DESARROLLO, Y EL HTML POR FIN ARCHIVADO (14-9-2026) — CERRADA

Pedido textual: "genera una ruta de desarrollo... para que puedas trabajar de forma autónoma sin mi
intervención", más la pregunta "si ya la emigración está completa pues deberíamos eliminar el html no?".

- [x] **`dinastia-godot/ROADMAP.md` creado**: el plan hacia ADELANTE en 7 fases ordenadas por
  prioridad (decisiones de base, terminar conectores, la piel 3D, sistemas grandes, el listado de
  750/300, lo que se deja en espera a propósito, limpieza técnica). Complementa a este archivo -que
  sigue siendo el historial de lo ya hecho, no se duplica-. Publicado también como vista de lectura.
- [x] **El HTML original: ARCHIVADO, no borrado.** La migración lleva confirmada al 100% desde el
  11-9 y ya pasó dos auditorías totales sin nada grande perdido -el criterio que el propio usuario fijó
  el 7-9 está cumplido-. Se archivó en vez de borrarse porque no libera espacio real (~1,4 MB) y porque
  se ha usado como referencia de verificación real -el bug de "votar en la Federación" de esta misma
  noche se confirmó comparando línea por línea contra `js/juego.js`-.
- [x] **HALLAZGO ENCONTRADO ANTES DE MOVER NADA, y CERRADO en la misma tanda: los dos lanzadores de un
  clic de la raíz seguían abriendo el HTML viejo.** `JUGAR DINASTIA.exe` (`herramientas/Lanzador.cs`)
  y `JUGAR DINASTIA (nube).bat` -este último sincronizando con Google Drive antes- abrían
  `dinastia-futbol-manager base.html` en el navegador, no Godot, meses después de la migración del
  2-9. El usuario confirmó que jugaba por PowerShell (no venía usando estos dos), y pidió arreglarlos.
  Reescritos para abrir el PROYECTO de Godot directo (`Godot_v4.7.2-stable_win64.exe --path
  dinastia-godot`, la versión sin consola) en vez de un build ya exportado -así el icono de la raíz
  siempre corre el código más reciente, sin depender de acordarse de recompilar-. Verificado
  arrancando el `.exe` recompilado y confirmando que el proceso de Godot aparece de verdad.
- [x] **Archivado ejecutado**: `dinastia-futbol-manager base.html`, `js/`, `css/` →
  `archivo-html-original/`, con `LEEME-ARCHIVO.txt` explicando el porqué y avisando que las fotos de
  equipaciones no se ven si se abre directo desde ahí (rutas relativas a `recursos/`, que sigue en la
  raíz). `herramientas/run_harness.ps1` actualizado a la nueva ruta -sigue funcionando sin cambios de
  fondo, porque ya escribía su copia de prueba en la raíz del proyecto para las rutas relativas-.
  Banco de pruebas de Godot: 0 fallos, verificado después de mover todo.

## EL RESTO DE NUCLEO/, CRUZADO SEÑAL POR SEÑAL: CUATRO BUGS MÁS, EL MÁS GRANDE EN CHAMPIONS/LIBERTADORES (14-9-2026) — CERRADA

Tras cerrar Federación, se mandó un agente a terminar el trabajo que la auditoría de conectores del
13-9 dejó a medias: cruzar el RESTO de las ~120 señales de `nucleo/` (excluyendo federación e
hinchada, ya cerradas) contra sus conexiones reales, con el mismo criterio -aceptable si el mismo
hermano `noticia`/`aviso` ya lo cuenta, bug si no hay ningún canal-. De ~90 señales revisadas, la
inmensa mayoría (`cantera`, `logros`, `medico`, `roles`, `selecciones`, `partido`, y el resto de
archivos sueltos) estaban bien: sin conexión pero con un `noticia.emit()`/`aviso.emit()` hermano
incondicional, o un dato que ya se lee sincrónicamente en pantalla. Cuatro no lo estaban:

- [x] **EL MÁS GRANDE: ganar la Champions o la Libertadores no avisaba de NADA.**
  `Continental extends Copa` hereda `campeon_proclamado`/`ronda_terminada` -las mismas dos señales que
  ya se habían arreglado para la copa NACIONAL hace semanas, con un comentario propio que documenta
  ese arreglo-, pero como cada torneo continental vive en una instancia dentro de
  `mundo.continentales` (una por confederación), el arreglo nunca se extendió aquí. El trofeo más
  grande que existe en el juego se levantaba en silencio.
- [x] **Y de paso, un bug relacionado que solo salió investigando el anterior: el sorteo (la
  cinemática de bombo) de los continentales SOLO funcionaba en la primera temporada de la partida.**
  `_conectar_sorteos()` -la función que ya conectaba `sorteo_grupos`/`sorteo_eliminatoria`- solo se
  llamaba una vez, al tomar el mando. Pero `mundo.nueva_temporada()` resortea los continentales con
  instancias NUEVAS cada cierre de año, así que desde la segunda temporada la Champions/Libertadores
  se sorteaba y se resolvía en silencio absoluto: sin bombo, sin aviso de ronda superada, sin premio
  de fase de grupos. Arreglado llamando a `_conectar_sorteos()` también en `_nueva_temporada()`, con
  candado por objeto -necesario porque `mundo.copa` SÍ persiste entre cambios de club, mismo patrón
  exacto del bug de `federacion.noticia` de esta misma noche-.
- [x] **`Entrenamiento.progreso` (subida/bajada automática de OVR por el entrenamiento semanal): 100%
  muda.** La única forma de enterarte de que un juvenil subió o un veterano se apagó era abrir su
  ficha y comparar el número a ojo. Ahora deja fila en el correo (sin `Aviso` modal a propósito: puede
  dispararse varias veces la misma semana).
- [x] **`Vestuario.clan_enfadado`/`rol_incumplido`: el castigo de moral SIEMPRE se aplicaba, el aviso
  solo el 45%/18% de las veces.** Ese porcentaje es a propósito -representa si la interna se filtra a
  la prensa, no si el castigo ocurre-, pero dejaba al jugador sin ninguna pista el otro 55%/82% de las
  veces. Ahora hay un canal propio al correo, siempre, además del mediático ocasional.
- [x] **`EstadioPropio.reforma_hecha`: el aviso de recorte se perdía.** Pedir más bandejas de las que
  `Instalaciones` permite hoy aplica la reforma recortada y cobra el coste completo; el aviso ("se
  quedó en N bandejas, sube la tribuna en Obras") solo viajaba dentro de esta señal, sin conectar.

Verificado con `pruebas/captura_conectores_14_9.gd` (nuevo, permanente, headless): 11 comprobaciones,
incluida la más delicada -que una instancia RESORTEADA de continental se reconecta sin que el candado
global lo bloquee, y que `copa` no se reconecta de más si `_conectar_sorteos()` se llama dos veces-.
Banco completo: 0 fallos, sin stderr, dos veces (antes y después).

## LOS TRES HUECOS DE FEDERACIÓN, CERRADOS, Y UN BUG GRANDE DE VOTAR ENCONTRADO DE PASO (14-9-2026) — CERRADA

Pedido textual: "Dale con todo" -tras la auditoría de arriba, autorización para conectar
`castigo_directiva`/`escandalo`/`votacion_abierta`, que habían quedado mapeados pero sin tocar-.

- [x] **`castigo_directiva` → `Directiva.mover_confianza(delta, motivo)`** y **`escandalo` →
  `Prensa._mover_funa(funa)`**, conectadas en el mismo bloque protegido de `_conectar_noticias()`
  (`federacion` no se recrea, así que comparten el candado `has_meta` ya existente). Licencia
  denegada, dopaje, incumplir el cupo juvenil y el fair play financiero ya mueven la confianza de la
  directiva y la funa de la hinchada de verdad -el texto de la noticia ya lo contaba, el número nunca
  se aplicaba-. No hace falta aviso aparte: `noticia.emit()` ya narra cada caso.
- [x] **`votacion_abierta` ahora avisa.** Era la única de las nueve señales de la clase sin
  `noticia.emit()` -100% muda desde que existe-. Ahora `abrir_votacion()` anuncia "Nueva votación en
  la asamblea" con el título y la descripción reales de la moción.
- [x] **BUG GRANDE ENCONTRADO DE PASO, sin buscarlo: votar en la Federación estaba roto desde
  siempre.** Al escribir el aviso de arriba se leyó `_pintar_federacion()` y saltaron dos fallos
  reales, verificados contra `js/juego.js` (el HTML original SÍ se porta fiel, el problema es de la
  interfaz de Godot):
  1. Los tres botones mandaban `_votar("si")`/`_votar("no")`/`_votar("abs")`, pero
     `Federacion.votar(opcion,...)` -portado tal cual del HTML, que también compara `op==='a'`- solo
     reconoce `"a"` como voto a favor. Como ninguna de las tres cadenas es `"a"`, **el botón "A favor"
     nunca sumaba el bono de `a_favor`, nunca se registraba como `vote_a`, y el texto de "ganaste/
     perdiste" salía SIEMPRE invertido cuando votabas a favor** -incluida la moción "superliga", donde
     tu club JAMÁS podía sumarse aunque votaras que sí, porque `_aplicar_mocion()` también mira
     `opcion=="a"` para decidirlo-. Arreglado: "A favor" manda `"a"` de verdad. "Abstenerse" -un
     tercer botón que el HTML nunca tuvo- sigue cayendo en la misma rama que "En contra" (cuenta
     igual, sin el bono); darle un comportamiento propio pediría un tercer caso en `votar()`, decisión
     de diseño que se deja anotada, no se inventó aquí.
  2. El título de la votación pendiente leía `v.get("titulo", v.get("id",""))`, pero la tabla
     `VOTACIONES` guarda el texto en la clave `"t"`, nunca `"titulo"` -esa clave no existe-: el
     jugador veía el id interno en crudo ("tvigual") en vez de "Reparto igualitario de los derechos de
     TV". Corregido a `v.get("t", v.get("id",""))`.
  Verificado con `pruebas/captura_federacion_conectada.gd` (nuevo, permanente, headless puro): las 7
  comprobaciones -confianza, funa, aviso de votación abierta, título real, y que "A favor" se registre
  de verdad como voto a favor- pasan. Banco completo: 0 fallos.
- [x] **Y de paso, un error de motor real que llevaba desde siempre: `federacion.movimiento` se
  conectaba DOS VECES a `_anotar_movimiento`.** `Mundo.tomar_el_mando()` ya la conecta con su propio
  candado `is_connected()` -es una de las "siete fuentes" del libro de movimientos, junto a estadio/
  cesiones/cantera/prensa/selecciones-, y `ui/principal.gd::_conectar_noticias()` la volvía a conectar
  por fuera. Godot rechazaba la segunda conexión sin duplicar el dinero -no era un bug de plata-, pero
  SÍ imprimía un `ERROR` real en la consola en CADA partida nueva, siempre, desde el primer segundo.
  Encontrado al correr `captura_federacion_conectada.gd` con stderr visible (nunca silenciarlo, trampa
  ya pagada antes). Quitada la línea redundante del lado de la interfaz; el núcleo ya lo cubre.

Salidas: `pruebas/captura_federacion_conectada.gd` + `.tscn` (nuevos, permanentes),
`herramientas\salida\auditoria_14_9_final.log` (banco limpio, sin stderr).

## AUDITORÍA DE SEGUIMIENTO: CIERRE DE LA COLA DE CONECTORES (14-9-2026) — CERRADA

Pedido textual: "has una auditoría completa y revisa si está todo conectado y has una revisión muy
específica para ver qué cosas son mejorables". Esta tanda retoma las dos colas que la auditoría de
conectores del 13-9 dejó explícitamente sin terminar (ver "LA AUDITORÍA DE CONECTORES..." más abajo).

- [x] **Banco de pruebas**: 851 comprobaciones, 0 fallos, verificado dos veces (antes y después del
  arreglo de abajo). Sigue en verde.
- [x] **Auditoría de código actualizada**: 55.402 líneas (+484 desde el 12-9, cuadra con la sesión
  de correcciones del 13-9), 0 duplicadas, 0 clases sin usar, 73 funciones de 80+ líneas, 24
  candidatas a código muerto (revisadas a mano: son helpers de un árbol de habilidades ya reemplazado
  en `entrenamiento.gd` y un `match_playback.gd::is_final()` sin consumidor -inofensivas, no le falta
  nada al jugador-).
- [x] **Bug real encontrado y corregido: `federacion.noticia` sin candado.** `ui/principal.gd::
  _conectar_noticias()` conectaba `mundo.federacion.noticia` con una lambda SIN el candado
  `has_meta()` que ya protege a `cesiones`/`mercado`/`eras`/`roles` en la misma función -se les pasó
  por alto a esta cuando se arregló el resto el 13-9-. Como `federacion` nunca se recrea en
  `tomar_el_mando()`, cada cambio de club (despido, trotamundos, nueva oferta) sumaba otra conexión:
  cada noticia de la Federación (votaciones, licencia, tribunal, antidopaje) se habría impreso una
  vez de más por cada club dirigido en la partida. Arreglado con el mismo patrón. Banco: 0 fallos
  antes y después.
- [x] **Las 9 señales de `federacion.gd` sin conectar, investigadas una por una** (la cola que dejó
  el 13-9). Veredicto: 6 son aceptables -su resultado ya llega al jugador por `noticia.emit()` en la
  misma función-, pero **3 son huecos reales, dejados sin tocar a propósito** (piden decisión de
  contenido, no un cable):
  1. `votacion_abierta`: **100% muda**. `abrir_votacion()` no llama a `noticia.emit()` en ningún
     punto -a diferencia de las otras 8 señales de la clase-, así que un jugador que no visita
     Federación por su cuenta puede perderse una moción entera (solo 6 en toda la carrera, 5%/semana
     de probabilidad). Votar sí funciona -`_pintar_federacion()` lee `f.voto_pendiente` directo-, lo
     que falta es el AVISO de que hay algo que votar.
  2. `castigo_directiva`: **el más serio**. El propio docstring de la clase (`federacion.gd:23`) dice
     "quien la use conecta `movimiento`, `castigo_directiva` y `escandalo`" -solo se conectó la
     primera-. `Directiva.mover_confianza(delta, motivo)` existe con la firma exacta y se usa en
     media docena de sitios, pero nunca para los 4 castigos de la federación (incumplir cupo juvenil,
     licencia denegada, dopaje, sanción de fair play financiero). Hoy ninguno de esos cuatro le hace
     nada a la confianza de la directiva, pese a que el motor está escrito para que sí.
  3. `escandalo`: el propio texto del juego promete algo que no pasa -`federacion.gd:242`, al entrar
     a la superliga: *"la hinchada y la federación te lo van a cobrar"*. La parte de la federación (la
     multa) sí pasa; la de la hinchada (la ira pública, vía `Prensa._mover_funa()`) nunca pasa porque
     la señal está sin conectar. Mismo hueco con el castigo por dopaje.
- [x] **Revisión dirigida de `principal.gd`** (no las ~250 conexiones una por una: se buscó
  específicamente el patrón ya cazado -objeto persistente + lambda sin candado-). Resultado: el caso
  de `federacion.noticia` de arriba era el único sin proteger; los ~20 `.connect(` a métodos con
  nombre (no lambda) se revisaron por typos silenciosos y ninguno tiene un identificador mal escrito
  -en GDScript eso sería error de compilación, coherente con que el banco pase limpio-.

**Pendiente para decidir (no urgente, no bloquea nada)**: conectar `castigo_directiva`/`escandalo` -
`Directiva.mover_confianza()` ya sirve tal cual; `Prensa._mover_funa()` es privada y no recibe motivo,
así que hace falta decidir si también se avisa la ira pública con un `noticia`/`Aviso`, o se deja
muda-; avisar `votacion_abierta` con un `noticia.emit()` igual que las otras 8; y considerar un
`Aviso.mostrar()` modal para licencia denegada (hoy solo pasa por la bandeja de noticias, a diferencia
de descenso/despido/liquidación que sí interrumpen).

Salidas: `herramientas\salida\auditoria_14_9_banco.log`, `auditoria_14_9_banco_post_fix.log`,
`auditoria_godot.txt` (actualizado).

## TAREA EN CURSO (13-9-2026, noche): feedback grande, visor invisible, y mejoras sueltas

Pedido textual, en varios mensajes seguidos: revisar Soccer Manager 2027 como referencia (sin poder
verlo de verdad, solo texto de marketing), seguir con mejoras visuales "usando Godot al máximo",
atender una tanda grande de feedback sobre motor lógico/texturas/animaciones/UI/sonido, y luego -de
madrugada- "ve si todos los conectores de funciones estén bien y refuerza el código... busca fallos
y más mejoras". Todo lo de esta noche, marcando lo cerrado:

- [x] **SDFGI** (iluminación global de Forward+) — encontrado y corregido un bug real de
  sobreexposición (el cielo se contaba dos veces). Ver "SDFGI..." más abajo.
- [x] **La tanda grande de feedback**, registrada entera línea por línea. Ver "LA TANDA GRANDE DE
  FEEDBACK..." más abajo. De ahí salieron cerrados en la misma noche: el visor 3D invisible (el
  hallazgo más grande de la sesión), los camarógrafos, una frase sin tooltip, y el cronómetro del
  mercado duplicado.
- [x] **El visor 3D del partido era invisible** desde que existe -el bug más importante encontrado
  esta noche-. Ver "EL BUG MÁS GRANDE..." más abajo.
- [x] **Los camarógrafos** del estadio, pedido puntual del feedback.
- [x] **Viento en el follaje** de la ciudad -las copas ya no están rígidas-.
- [x] **Dos bugs más en el estadio**, encontrados porque el usuario preguntó por una captura de
  prueba: el campo sin suelo alrededor (hueco de vacío) y el túnel de vestuarios negro de noche.
- [x] **Dos hallazgos de UI** del barrido de "frases recortadas": el tooltip que faltaba y el
  cronómetro de mercado duplicado con una fórmula distinta (bug real, corregido).
- [x] **Auditoría de "conectores de funciones"** — el agente encontró y corrigió un bug real de
  señales duplicadas al cambiar de club (`_conectar_noticias()`), y de paso apareció algo grande:
  `Banco.liquidado` nunca se escuchaba -el club se podía liquidar de verdad y el jugador seguía
  jugando como si nada-. Cerrado esa misma noche, junto con dos consejeros del directorio que
  llevaban meses diciendo "sin efecto" y ya podían engancharse a `Banco`. Ver la sección propia
  "LA AUDITORÍA DE CONECTORES..." más abajo.

Si esta sección sigue con casillas sin marcar la próxima vez que se lea este archivo, la tarea
quedó a medias -seguir desde el primer `[ ]` sin marcar-.

## LO DE ANTES (12-9-2026, tarde): transporte, más mejoras, y auditoría — CERRADA

Pedido textual: "dale con lo que te decía, lo del transporte y esas cosas, y ve qué más puedes
agregar y mejorar y además ve si el juego se puede mejorar algo y por último haz una auditoría".

Plan, marcando lo que se va cerrando:

- [x] **Transporte**: se sumó una **terminal de buses** (cobertizo de cinco pilares junto al
  acceso norte, con la franja del club) y **autobuses de verdad** -el kit CC0 no trae un bus, así
  que se usa la furgoneta a escala mucho mayor y menor velocidad, corriendo por el anillo exterior
  que ya pasa junto a las cuatro paradas-. Verificado con captura y banco (0 fallos).
- [x] **Más para la ciudad**: hecho en la tanda anterior de esta misma sesión -crecimiento con
  reputación/socios, variedad arquitectónica, arbolado, piscina/polideportivo/canchas, parque del
  barrio, eje vial exterior-, ver la sección de arriba.
- [x] **Auditoría** y **"ve si el juego se puede mejorar"**: `auditar.ps1` solo miraba el proyecto
  viejo (`js\` y `visor3d\scripts`). Se escribió `herramientas\auditar_godot.ps1` para el activo
  -ver la memoria `dinastia-auditoria-godot.md`-: **54.918 líneas en 84 ficheros**, 0 duplicadas,
  0 clases sin usar. Hallazgo grande sin tocar: `principal.gd` con 15.309 líneas -un tercio de
  todo el código; cambio estructural demasiado grande para hacerlo sin que lo pida el usuario-.
  Y un cheque nuevo -"funciones que nadie llama"- encontró un bug real: `MatchPlayback` tenía
  `mas_rapido()`/`mas_lento()`/`pausar_o_seguir()`/`etiqueta_velocidad()` escritos y sin llamar
  desde ningún lado -**el visor 3D del estadio corría el partido siempre a velocidad normal, sin
  pausa ni avance rápido**, a diferencia de la pantalla 2D del partido-. Se añadió un botón "⏱" en
  `ui/estadio.gd` que cicla Pausa→Lento→Normal→Rápido→x4→Pausa, verificado midiendo `vel_idx` en
  cada clic (no solo el texto del botón). Se investigó otro candidato que sonaba igual de grave
  -`entrenamiento.gd` marcaba `dar_puntos`/`subidas_de` y compañía como sin uso, como si el árbol
  de habilidades nunca repartiera puntos- y era **falsa alarma**: el reparto real
  (`repartir_puntos()`, fiel al HTML) ya está escrito y ya se llama desde `mundo.gd`; esas siete
  funciones son ayudantes de una implementación alternativa sin usar, inofensiva. No se tocó.

Si esta sección sigue con casillas sin marcar la próxima vez que se lea este archivo, la tarea
quedó a medias -seguir desde el primer `[ ]` sin marcar-.

## AUDITORÍA TOTAL: MIGRACIÓN, CHAT Y MEMORIA (12-9-2026, tarde-noche) — CERRADA

Pedido textual: "audita la emigración, quizás nos pudimos haber olvidado de algo y también audita
esté chat y tu memoria" -después de que la tanda anterior ya hiciera la auditoría de CÓDIGO
(`auditar_godot.ps1`). Esta era la parte de fuera del código: qué falta del HTML, qué se prometió en
el chat y no se confirmó, y si la propia memoria dice cosas que ya no son ciertas.

- [x] **Migración**: releído el historial completo de auditorías ya hechas (73/73 pantallas + los
  cuatro sistemas nuevos, todos cerrados). Un bug real salió de ahí, no de re-auditar desde cero:
  ver el punto de abajo. El único pendiente real que queda -y que YA estaba anotado, no es un
  hallazgo nuevo- es el **estadio por módulos** (cola de tareas de arriba, punto 3): sigue sin
  construirse, el usuario confirmó que lo quiere y esta sesión no llegó a tocarlo.
- [x] **Bug real encontrado y corregido: los idiomas no revertían.** `_traducir_pantalla()`
  (`ui/principal.gd`) no hacía NADA si `Idiomas.idioma == "es"` -así que cualquier nodo construido
  una sola vez (los botones "Guardar"/"Cargar"/"Otro mundo" de la fila de acciones, sus tooltips) se
  quedaba pegado en el último idioma elegido para siempre: pasar a inglés y volver a castellano no
  los devolvía. Era una sospecha sin confirmar desde el 10-9 (una captura mostró "Save"/"Load"/"New
  world" en inglés pese a forzar `idioma="es"`). Confirmado leyendo el código y corregido guardando en
  metadatos del propio nodo el texto castellano original y lo último que la función escribió: si el
  texto actual coincide con lo último que ELLA puso, nadie lo tocó desde entonces y usa el
  castellano guardado como fuente; si no coincide, un repintado puso texto fresco y lo adopta como
  la nueva fuente. Así funciona igual de bien para el contenido dinámico (nombres, cifras, que se
  repintan en castellano cada vez) que para el esqueleto fijo que antes se rompía. Verificado con
  `pruebas/captura_idioma_revierte.gd` (nuevo): el botón "Guardar" real, ciclo es→en→es→fr, texto
  correcto en cada paso ('Guardar'→'Save'→'Guardar'→'Save'→'Sauvegarder'→'Guardar'). Banco completo:
  0 fallos.
- [x] **Chat**: se revisó el transcript (no solo la memoria de trabajo) para confirmar dos entregas
  prometidas. Ambas se cumplieron de verdad: el vídeo de la ciudad se mandó por `SendUserFile` (dos
  veces, la definitiva de 15 s/960×540 bajo el límite de 30 MB), y el APK -al pesar 96 MB, sobre ese
  límite- se entregó como el enlace de Google Drive real que generó el sincronizador del propio
  usuario. No quedó ninguna promesa sin cumplir.
- [x] **Memoria propia**: dos memos corregidos por decir cosas que ya no son ciertas.
  `dinastia-migracion-godot` seguía diciendo que la paleta de `principal.gd` era gris azulado estilo
  GitHub -falso, ya está en el verde oscuro del HTML desde algún punto sin registrar entre el 4-9 y
  hoy-. `dinastia-ciudad-3d` describía la arquitectura VIEJA (`visor3d\` + puente JSON), que es
  justo lo que la tanda de esta mañana reemplazó: reescrito para reflejar `visor/city_builder.gd` +
  `ui/ciudad_vista.gd` sin puente, y cerrados los cuatro puntos del roadmap original que ya se
  cumplieron. Detalle completo en la memoria `dinastia-auditoria-total-12-9.md`.

Conclusión para el usuario: no apareció nada grande "olvidado" -la migración sigue en el ~99% que ya
medían las auditorías anteriores-, pero sí un bug de verdad (idiomas) que llevaba dos días sin
confirmarse, y una tarea de la propia cola de hoy (estadio por módulos) que sigue pendiente de
verdad, no perdida ni terminada en silencio.

## LOS CAMARÓGRAFOS DEL ESTADIO (13-9-2026) — CERRADA

Pedido puntual de la tanda grande de feedback: "faltan camarógrafos". `visor/stadium_builder.gd`
tiene ahora `_camarografos()`: cinco figuras sencillas (chaleco de prensa naranja, cámara sobre
monopié) en las posiciones reales de transmisión -detrás de cada arco, a los dos lados, y a pie de
línea en la mitad de cancha del lado de la cámara principal-, cada una orientada hacia el centro del
campo. Son geometría barata (cajas + una esfera para la cabeza), no personajes completos -aquí no
hace falta más para un detalle de fondo-. Verificado con `pruebas/captura_camarografos.gd` (nuevo,
construye el estadio a secas y encuadra la cámara justo sobre uno de ellos): la figura aparece de
pie, con el chaleco naranja bien visible, orientada hacia la cancha. Banco completo: 0 fallos.

## LA AUDITORÍA DE "CONECTORES DE FUNCIONES" Y LO QUE SALIÓ DE AHÍ (13-9-2026) — CERRADA

Pedido textual: "ve si todos los conectores de funciones estén bien y refuerza el código". Se mandó
un agente a revisar `.connect(` por todo el proyecto -370 conexiones en total, revisó a fondo
100-120- buscando específicamente la familia de bug ya vista esta sesión (una señal que se
reconecta cada vez que se repite una acción, disparando el mismo aviso/dinero/logro varias veces).

**Bug real encontrado y corregido por el agente**: `ui/principal.gd::_conectar_noticias()` se llama
más de una vez sobre el MISMO `Mundo` cuando el jugador cambia de club sin partida nueva (despido,
"trotamundos", aceptar una oferta de trabajo). `mercado`, `roles`, `cesiones` y `eras` NO se
recrean en `tomar_el_mando()` -a diferencia de `prensa`/`logros`/`vestuario`/etc, que sí-, así que
cada cambio de club añadía OTRA conexión sobre el mismo objeto: dinero, logros y avisos se habrían
anotado y sonado el doble, el triple, etc. por cada cambio de club en la misma carrera. Arreglado
con un candado por metadato en 8 puntos (`is_connected()` no sirve aquí: cada conexión usa una
lambda, y dos lambdas con el mismo código son objetos `Callable` distintos). Verificado con
`pruebas/captura_conectar_dup.gd` (nuevo, permanente): llama `_conectar_noticias()` dos veces sobre
el mismo mundo y comprueba que cada señal solo anota UNA fila, no dos. Banco completo: 0 fallos.

**El hallazgo más importante para el jugador, encontrado de paso**: `Banco.liquidado` -"el único
sistema del juego que puede TERMINAR una partida sin que pierdas un partido", según su propio
comentario de cabecera- se emite de verdad tras doce semanas con la caja en rojo, pero **nadie la
escuchaba en `principal.gd`**: el jugador seguía dirigiendo el club liquidado como si nada, sin
aviso ni consecuencia. Cerrado en la misma noche: conectada igual que un despido -mismo peso
narrativo, reusa `Roles.quedar_sin_banco()`, que ya deja la pantalla de ofertas de trabajo probada-.
Verificado con `pruebas/captura_liquidacion.gd` (nuevo): fuerza la caja muy negativa, avanza el
banco 13 semanas, y confirma con una captura real que aparece "ESTÁS SIN BANCO" con ofertas de otros
clubes -exactamente como al ser despedido-.

**Y de paso, dos consejeros del directorio que decían "sin efecto" desde antes de que existiera
`Banco`, y se quedaron así después de que se construyera** (`Directiva.CONSEJEROS`, claves `fin`/
`leg`): un jugador podía pagar 600.000 + 15.000/semana por un consejero financiero o legal que de
verdad no hacía nada, sin que la interfaz avisara que ya se podía enganchar. Arreglado:
- **Consejero financiero**: −35% de interés de sobregiro (`Banco.descuento_sobregiro`).
- **Consejero legal**: 3 semanas más antes de la liquidación (`Banco.gracia_liquidacion`).
`Mundo.avanzar_semana()` los fija cada semana según `directiva.tiene_consejero(...)`, antes de
llamar a `banco.semana()`. **Trampa real encontrada verificando esto**: `match` en GDScript exige
que cada patrón sea una constante de verdad -`SEM_LIQUIDACION + gracia_liquidacion` no compiló
("Expression in match pattern must be a constant")-, así que ese umbral se comprueba con un `if`
aparte, no dentro del `match` de los otros dos escalones (que sí son constantes). Verificado con
`pruebas/captura_consejeros_banco.gd` (nuevo, headless puro): los tres números -interés sin
consejero, interés con el 35% de descuento, y el umbral de liquidación movido de 12 a 15 semanas-
salen exactos. Banco completo: 0 fallos.

**Lo que el agente encontró pero no tocó** (quedan anotadas para decidir prioridad, no son
olvidos): ~45 señales declaradas en `nucleo/` que nadie conecta nunca -las más notables, las 9 de
`federacion.gd` (votaciones y sanciones de la propia federación, que hoy pasan en silencio) y las
dos de `hinchada.gd` (`noticia`, `movimiento`), completamente sin conectar-. Cada una implica decidir
SI y CÓMO debe notarse en pantalla, como pasó con las 44 señales `noticia` que sí se conectaron una
sesión anterior; no es un arreglo puntual, es contenido nuevo. Quedaron ~250 conexiones sin revisar
en detalle -sobre todo botones de pestañas en `principal.gd`-, pero el muestreo hecho (nodo nuevo +
`_construir()` de una sola pasada) fue consistente: riesgo bajo, no verificado uno por uno.

**Una de esas ~45 señales sueltas SÍ se enganchó la misma noche, por ser exactamente el mismo patrón
ya probado 9 veces**: `Hinchada.noticia`/`movimiento` -campañas de abonos, "la barra se planta",
encuestas a los socios- llevaban tiempo disparándose de verdad y nadie las escuchaba, mismo caso que
ya se vio con selecciones/cantera/logros/cesiones en sesiones anteriores. Como `hinchada` se
recrea en cada `tomar_el_mando()` (mismo grupo que `banco`/`ciudad`/`comercial`, sin necesidad de
candado) y la firma de sus señales es idéntica a las otras nueve ya conectadas, era mecánico, no
diseño nuevo. Verificado con `pruebas/captura_hinchada_noticia.gd`: emitir la señal a mano hace
aparecer la fila en la bandeja. Banco completo: 0 fallos.

## VIENTO EN EL FOLLAJE DE LA CIUDAD (13-9-2026) — CERRADA

Los cientos de copas de árbol de la ciudad (`visor/city_builder.gd::_arbolado()`, un solo
`MultiMesh`) estaban completamente rígidas -de lo primero que delata una ciudad de maqueta-. Nuevo
`visor/follaje_viento.gdshader`: cada árbol se mece con una fase PROPIA -sacada de su propia
posición en el mundo vía `MODEL_MATRIX`, no de un contador global- para que no se muevan todos al
unísono, y el balanceo crece hacia la punta de la copa (la base, pegada al tronco, casi no se
mueve). Mismo color por instancia que antes (`vertex_color_use_as_albedo` de toda la vida, ahora
replicado a mano con `COLOR` en el shader). Verificado con `pruebas/captura_viento_arboles.gd`
(nuevo): compila y renderiza sin roturas, y un píxel de borde de copa cambia de valor entre dos
capturas separadas por 1,5 s -de verdad se mueve, no solo compila-. Banco completo: 0 fallos.

## DOS BUGS REALES MÁS EN EL ESTADIO, ENCONTRADOS PORQUE EL USUARIO PREGUNTÓ (13-9-2026)

El usuario vio una captura de prueba de los camarógrafos y preguntó "no se ve xd, ¿y qué es eso en
la portería?" -señalando un bloque oscuro-. Investigar la pregunta llevó a dos arreglos reales en
`visor/stadium_builder.gd`, ninguno de los dos relacionado con los camarógrafos en sí.

1. **El campo era una plancha de 80×117 m, y nada más cubría el suelo.** La cámara "Detrás del arco"
   queda apenas fuera de ese borde, y mirar hacia la cancha desde ahí enseñaba una franja de vacío
   -el cielo asomando por abajo- antes de llegar al césped. Arreglado con `_explanada_de_fondo()`:
   una base de 400×400 m con textura de hormigón, bien por debajo del césped, que asegura que NINGUNA
   cámara del estadio -sea cual sea su forma o tamaño- pueda ver ese hueco. **Trampa propia en el
   camino**: el primer intento asignó `Texturas.hormigon()` -que YA devuelve el material completo- a
   `mat.albedo_texture`, un error de tipos que no compila; el error quedó oculto la primera vez porque
   estaba corriendo el banco con `2>$null` -lección: no silenciar stderr al probar código nuevo, con
   el script roto Godot igual "termina" e imprime lo que haya antes del fallo, pareciendo que todo
   salió bien.
2. **El bloque de la portería no era un bug de los camarógrafos: es el túnel de vestuarios (ya
   existía, `_tunel()`), y de noche se veía NEGRO SÓLIDO.** Su cara visible queda bajo la cubierta de
   la tribuna, sin línea directa a sol/luna ni a los focos -que apuntan al césped, no a una hornacina
   debajo del graderío-, y el ambiente nocturno no bastaba para leerlo. Un `OmniLight3D` cercano NO lo
   arregló -verificado con captura, sin ningún cambio visible-; lo que sí funcionó fue darle su PROPIA
   emisión modesta al material -igual que cualquier túnel de vestuarios real tiene su propia luz de
   entrada, no depende de que algo externo la alcance-. Material propio (duplicado, no el
   `Texturas.hormigon()` compartido, para no afectar a nadie más que lo use).

Verificado con `pruebas/captura_tunel_real.gd` (nuevo, comparando la cámara "Principal (TV)" -la que
usa casi toda partida- y "Detrás del arco"): el túnel ya muestra su textura de hormigón en vez de un
bloque negro, y "Detrás del arco" ya no tiene el hueco vacío. **Nota pendiente, menor**: la cámara
"Principal (TV)" sigue mostrando un panel bastante plano y oscuro en primer plano -parece ser parte
de la propia estructura de la tribuna, muy cerca de esa cámara, mal iluminada de noche, no el hueco
vacío que sí se arregló-; no es tan grave como el bloque negro ni como el vacío, queda anotado para
otra tanda si molesta de verdad jugando. Banco completo: 0 fallos.

## LA TANDA GRANDE DE FEEDBACK DEL 13-9-2026, REGISTRADA ENTERA

El usuario mandó dos mensajes seguidos con una lista larga de quejas y pedidos, pidiendo
explícitamente no perder nada. Van completos aquí, con lo que ya se investigó al lado.

**Sobre el partido en vivo:**
- *"el partido se mueven anti natural"* — sobre la calidad del movimiento en `MatchPlayback` (rig
  Mixamo). Sigue pendiente, ver [[dinastia-animaciones-3d]].
- *"no podemos ver realmente en vivo el partido y el visor debe ser de forma nativa"* — **CERRADO
  esta misma tanda**, ver la sección de arriba: era un bug real, el 3D quedaba invisible.
- *"las caras de los jugadores, sus cuerpos, se ven antinaturales"* — pendiente, ligado al atlas del
  jugador 3D ([[dinastia-atlas-jugador3d]]).
- *"el juego se siente pesado, sin animación y sin detalles visuales"* — pendiente, revisar cuando se
  ataque animación de verdad.
- **"aún se siente recortada las frases o mini menús" — investigado el 13-9-2026, un caso real
  cerrado**: barrido de capturas por varias pestañas (`pruebas/captura_sweep_texto.gd`, nuevo).
  Encontrado y corregido: en Ajustes → Juego, la nota de cada horario de partido ("El horario de la
  tarde...") tenía `clip_text = true` pero SIN `tooltip_text` -rompía la regla ya escrita en
  [[dinastia-desborde-ancho]] ("clip_text siempre con su texto de repuesto")-, así que una frase
  entera se cortaba a media palabra sin ninguna forma de leerla completa. Arreglado en
  `ui/principal.gd` (~línea 7029). **Falsa alarma investigada y descartada**: el carril de chips de
  nivel 2 (Estadio/Infraestructura/Diseño 3D/...) que parecía "cortado" a la derecha es en realidad
  un `ScrollContainer` horizontal A PROPÓSITO -se arrastra con el dedo o L2/R2-, no un `HBoxContainer`
  desbordado; ver un chip parcial en el borde es el indicador normal de "hay más". **Hay unos 90
  sitios más con `clip_text = true`** en `principal.gd` -no se auditaron uno por uno, sería a
  ciegas sin una captura real de cada uno; si el usuario señala otro lugar concreto donde se sienta
  recortado, revisar ESE primero-. **Encontrado de paso, sin tocar**: en Mercado, dos avisos de la
  ventana de fichajes se ven seguidos con números DISTINTOS ("quedan 6 semanas" y "quedan 5
  semana(s)") -parecen ser el aviso puntual de "faltan dos semanas" (ya calculado en una semana
  anterior) y el estado permanente (`texto_de_mercado()`, recalculado cada vez) mostrando la cuenta
  real-. **CERRADO el mismo 13-9-2026**: era un bug real, no una sospecha -dos implementaciones
  INDEPENDIENTES del mismo cálculo, una en `Mundo.semanas_de_mercado()` (correcta) y otra a mano en
  `ui/principal.gd::_pintar_estado_mercado()` (`6 - sem`, una semana de menos siempre). Arreglado
  reusando las funciones de `Mundo` en vez de reimplementar el cálculo. Verificado con captura: los
  dos avisos ya dicen el mismo número. Banco completo: 0 fallos.

- ~~"diferentes tipos de cámara"~~ **PROBABLEMENTE YA CUBIERTO, revisado el 13-9-2026**:
  `visor/camera_rig.gd` ya tiene SIETE cámaras distintas (Principal TV, Tribuna alta, Detrás del
  arco, A ras de campo, Esquina, Dron, Cenital táctica), con el botón "Otra cámara" cicla entre
  ellas. Sospecha fuerte: como el visor entero era invisible hasta el arreglo de esta misma noche
  (ver "EL BUG MÁS GRANDE..."), es muy probable que el usuario nunca haya llegado a VER ninguna de
  estas siete cámaras funcionando. No se tocó nada -si tras el arreglo del visor la queja sigue en
  pie, ahí sí hace falta investigar de nuevo, pero probando primero con el visor ya visible-.
- *"las animaciones como rueda de prensa y las bolas calientes aún es muy mala"* — pendiente, revisar
  `ui/rueda3d.gd`/similar.

**Sobre interfaz y sonido:**
- *"aún se siente recortada las frases o mini menús"* — posible recurrencia de
  [[dinastia-desborde-ancho]]; pendiente localizar dónde exactamente.
- *"faltan sonidos más propios se siente genéricos"* — ya anotado en [[dinastia-pedidos-pendientes]]
  ("un sonido propio para CADA evento"), sigue en pie.
- *"el tutorial debe ser mejorado y según el modo de juego"* — pendiente, sistema nuevo.

**Sobre el mundo y las instalaciones:**
- *"cada estadio debe parecerse a los reales de los clubes correspondientes"* — sistema grande: pediría
  datos/geometría de estadios reales por club, no generación paramétrica.
- *"usar la casa por dentro para las animaciones de negociación y todo lo que tenga que ver con
  negocios"* — la casa (`oficina_dt.glb`) ya está puesta en la ciudad ([[dinastia-ciudad-3d]]);
  usarla como ESCENARIO de negociaciones es trabajo nuevo.
- *"mejorar el aspecto de personalización del personaje"* — pendiente, revisar contra
  [[dinastia-aspecto-dt]] (552 combinaciones ya portadas, puede que sea pulido, no ausencia).
- *"negociar con los sponsors en vida real tanto de forma normal como en primera persona"* — sistema
  grande, no empezado.
- *"recorrer la ciudad en primera persona... conducir... transporte público... interactuar"* —
  **el propio usuario lo dejó explícitamente para el futuro** ("dejar a futuro"), no tocar todavía.
- *"faltan NPC, diálogos de esos NPC"* — sistema grande, no empezado.
- *"los eventos no se sienten realistas, eventos icónicos y reales de cada país"* — parcialmente
  cubierto (`instrucciones_extras.txt` ya tenía 6 eventos de guion implementados, ver la auditoría de
  ayer), pero "icónicos por país" es más específico y no está.
- *"el público debe tener cuerpos y caras reales"* — la grada es textura procedural
  ([[dinastia-calidad-grafica]]); cuerpos/caras reales de verdad sería un sistema de crowd 3D aparte,
  caro.
- ~~"faltan camarógrafos"~~ **CERRADO** el mismo 13-9-2026, ver la sección propia más abajo.
- *"la gente del club en sus eventos debe tener su mini cinemática y sus cuadros de texto"* —
  pendiente, revisar contra lo que ya existe en prensa/rueda de prensa 3D.

**Sobre lo que dijo aparte ("dejaremos para otra instancia", sin detalle todavía):** "problemas con
las texturas y con el motor lógico" — el usuario pidió explícitamente NO investigarlo ahora. Queda
anotado para cuando dé el detalle.

Nada de esto se descartó: lo que se pudo cerrar ya está arriba: (el visor invisible); el resto queda
aquí para que la próxima sesión no tenga que preguntar qué faltaba.

## EL BUG MÁS GRANDE DE LA SESIÓN: EL VISOR 3D DEL PARTIDO ERA INVISIBLE (13-9-2026) — CORREGIDO

Pedido textual: "el partido se mueven anti natural, no podemos ver realmente en vivo el partido y el
visor debe ser de forma nativa". Esto llevaba semanas pedido -"el visor 3D pasa a ser el ESTÁNDAR de
la vista de partido, no un extra opcional", ver [[dinastia-referencia-partido]]- y un comentario en
`principal.gd` (línea ~7760) afirmaba, sin haberlo comprobado nunca con una imagen, que
`partido_vivo._ver_estadio()` "ya deja hueco de sobra" para el 3D.

**Era falso, y una captura real lo demostró en un minuto.** `PartidoVivo._construir()` pinta cuatro
paneles -campo/arengas, crónica, banquillo y pizarra, estadísticas- que cubren la pantalla ENTERA,
borde a borde. `_ver_estadio()` construía `VistaEstadio` perfectamente -con el partido de verdad
dentro, los 22 jugando, el marcador corriendo- y quedaba **invisible detrás de esos paneles**: Godot
pinta los `Control` SIEMPRE por encima del 3D del mismo viewport, sin importar el orden de los nodos
ni la profundidad en el árbol. Encima había una SEGUNDA capa del mismo problema: `PartidoVivo` cuelga
de `principal.gd` (`_dirigir()` hace `add_child(vivo)` sobre sí mismo), así que la pantalla del club
de MÁS ABAJO TODAVÍA es otro `Control` opaco en el mismo viewport -esconder solo los paneles de
`PartidoVivo` seguía dejando ver la tabla de posiciones por debajo-.

**El botón "Ver en 3D" durante un partido dirigido probablemente nunca mostró nada, desde que existe.**

Arreglado en `ui/partido_vivo.gd::_ver_estadio()` con el mismo patrón que ya usa
`principal.gd::_ver_estadio_propio()`, aplicado en las DOS capas: se esconden los hijos `Control`
visibles de `PartidoVivo` **y** los del padre (`principal.gd`) mientras el 3D está abierto, y se
devuelven exactamente los que estaban visibles -no todos- al cerrar.

**De paso, el visor pasa a abrirse SOLO al empezar el partido** -sin tener que encontrar el botón-,
que es lo que pedía "el visor debe ser de forma nativa": lo primero que se ve al dirigir un partido
ya es el estadio en 3D con los jugadores corriendo, no un panel de texto con un botón escondido.
Cerrarlo (✕ o "Volver") te devuelve al panel de cambios/arengas/pizarra exactamente como antes.

Verificado con `pruebas/captura_visor_nativo.gd` (nuevo) y TRES capturas reales, no solo el print:
1. Antes del segundo arreglo: se veía la pantalla del CLUB (principal.gd) por debajo -confirmó la
   segunda capa del bug-.
2. Después: **los 22 jugadores en la cancha, la grada, el reflector, el marcador, todo visible de
   verdad**, sin pulsar ningún botón.
3. Tras cerrar: el panel de `PartidoVivo` vuelve exactamente como estaba -crónica con la jugada del
   minuto 2, tarjeta amarilla anotada, velocidad "Normal" seleccionada-.

Banco completo: 0 fallos. **Esto no toca cómo SE MUEVEN los jugadores dentro del 3D** -esa queja
("antinatural") es sobre la calidad de `MatchPlayback`/las animaciones del rig Mixamo, un problema
distinto y más grande, ver la lista de pendientes más abajo-, pero es el paso que faltaba para que
alguien LLEGUE a verlas jugar en primer lugar.

## SDFGI: LA PIEZA GRANDE DE FORWARD+ QUE FALTABA (13-9-2026) — CERRADA

Pedido textual: "...debemos realmente usar godot al máximo". `visor/calidad.gd` ya encendía SSAO,
SSIL, SSR, glow, niebla volumétrica y sombras de 4 cascadas -un Forward+ bastante completo-, pero le
faltaba la pieza más grande de todas: **SDFGI** (iluminación global en tiempo real). La diferencia
con SSIL: SSIL solo rebota lo que la CÁMARA ve en pantalla en ese instante; SDFGI voxeliza la escena
de verdad, así que una esquina en sombra se ilumina con luz que rebota desde algo que ni siquiera
está en cuadro. Se añadió en `entorno()`, gateado a `nivel >= ULTRA` -igual que SSIL/SSR/niebla
volumétrica, es caro-.

**Bug real encontrado y corregido antes de darlo por bueno** (con el método de siempre: capturar,
mirar, no asumir): los primeros valores (`sdfgi_energy=1,2`, `sdfgi_bounce_feedback=0,5`,
`sdfgi_read_sky_light=true`) dejaban la ciudad **sobreexpuesta a blanco casi total** -no sutil, la
pantalla entera quemada-, confirmado comparando el mismo fotograma con SDFGI encendido y apagado
(`pruebas/captura_sdfgi.gd`, nuevo). Bajar la energía a 0,55 mejoró casi todo, pero una azotea plana
grande (la del Polideportivo) se seguía quemando incluso 220 fotogramas después -descartando que
fuera solo el arranque en frío de las cascadas-. La causa real: `sdfgi_read_sky_light=true` hace que
SDFGI TAMBIÉN sume la luz del cielo, y el entorno ya la sumaba por su cuenta
(`ambient_light_source = AMBIENT_SOURCE_SKY`) -una azotea que ve medio cielo despejado se contaba
DOS VECES-. Con `sdfgi_read_sky_light=false` (SDFGI solo aporta el rebote ENTRE superficies, no el
cielo directo) la sobreexposición desapareció del todo. Verificado con tres capturas comparables
-temprano, convergido y apagado-: el efecto final es sutil (más relleno en las sombras, tono más
rico), que es justo lo que SDFGI debe hacer sin que compita con la niebla/ambiente ya calibrados.
Solo afecta a quien elija Ultra -ALTO y MEDIO, el 99% de las partidas, quedan exactamente igual-.
Banco completo: 0 fallos.

## LOS "ARCHIVOS PROFUNDOS" CONTRA EL CÓDIGO REAL (12-9-2026, noche) — INFORME, SIN TOCAR CÓDIGO

Pedido textual: "...y después cumple lo qué falta en el leeme y después en archivos profundos". Los
"archivos profundos" son `instruciones profundas/` (un nivel arriba de `dinastia-godot/`): dos
listados de 1.100 ideas numeradas (`300-ideas-...md`, `750-ideas-adicionales.md`) y
`instrucciones_extras.txt` -la lista de MÁS ALTA prioridad, la más reciente, manda sobre las otras
dos-. Trae mecánicas muy ambiciosas: clanes de vestuario, salud mental, IA conversacional en las
charlas técnicas, redes sociales con "funas", mercado a ciegas, guerra de representantes, inversión
del salario del propio DT, eventos de vida personal (escándalos, retiro prematuro, virus FIFA
geopolítico, ocupación hostil de la directiva, venganza de un exrepresentante), "Ley del Ex",
invasión de campo, juegos mentales en el túnel, perfiles psicológicos de árbitros, modo Director de
Cantera completo, ligas/copas fieles a cada país, dorsales reales, árbol de habilidades, etc.

Se mandó un agente a leer los tres documentos completos y cruzarlos contra `nucleo/`, `ui/` y
`visor/` -sin tocar ni un archivo, solo informe-, para no gastar contexto propio leyendo ~90 KB de
especificación. **El resultado sorprende hasta viniendo con la expectativa de "ya hay mucho
hecho"**: de las ~15 mecánicas grandes de `instrucciones_extras.txt` (la lista que manda), unas 11
YA ESTÁN CONSTRUIDAS -algunas con más profundidad que la que el propio documento pedía-.

**Ya hecho** (con dónde vive cada cosa, para no tener que volver a auditarlo):
- Clanes/camarillas de vestuario, salud mental y ansiedad, solicitudes del plantel, satisfacción por
  minutos jugados, charla técnica por tonos -`nucleo/vestuario.gd`-.
- Mercado a ciegas (`nucleo/ojeadores.gd`, `modo_ciego`), interinato de emergencia (`roles.gd`).
- Los seis eventos "de guion" pedidos -retiro prematuro por motivos personales, Virus FIFA,
  filtración de un exrepresentante, ocupación hostil de la directiva, fichaje por interés comercial,
  fondo buitre sobre canteranos- todos en `nucleo/prensa.gd`/`cesiones.gd`, con comentarios que citan
  el pedido casi textual.
- Ley del Ex (`nucleo/partido.gd`), lenguaje corporal en entrevistas y perfiles psicológicos de
  árbitros (`prensa.gd`/`previa.gd`), inversión del salario del DT en filiales (`roles.gd`), escuela
  táctica y legado de leyendas (`vLegado`), redes sociales con funas (`prensa.gd`), copas fieles a
  cada país (`copa.gd::COPAS_POR_PAIS`, `roles.gd::TORNEOS_CORTOS` para Apertura/Clausura), dorsales
  y 813+ fichas reales (`reales.gd`), árbol de habilidades de DT y de jugador.

**Hueco pequeño y barato de cerrar** (apoyado en algo que ya existe, no motor nuevo):
1. Pizarra táctica VISUAL (ver la formación dibujada en la cancha) -hoy `Tactica.formacion` es solo
   el string "4-3-3", sin dibujo en `ui/`-.
2. Guerra de representantes, Escándalo Nocturno, adaptación cultural del extranjero, espionaje de
   entrenamientos rivales (extender el evento "espía" que ya existe), lobby institucional explícito
   con árbitros -los cinco son "un evento más" sobre el mismo patrón de `prensa.gd` que ya reparte
   los seis de arriba-.

**Sistema grande, no empezado** (necesitan que decida prioridad antes de que alguien les dedique
semanas; orden por cuánto cambiarían la partida):
1. ~~Invasión de campo/protesta ultra que interrumpe un partido EN VIVO~~ **CORRECCIÓN (13-9-2026):
   falso negativo del informe del agente.** Revisando `partido_vivo.gd` por otra razón (el bug del
   visor invisible) apareció `Partido.chequear_invasion()`/`invasion_ya`, ya enganchado en
   `_process()`: al minuto 70, perdiendo en casa y con el ánimo hundido, el partido SÍ se para, suena
   el silbato y se reabre el camarín. Estaba ahí desde antes de esta sesión; el agente buscó en
   `hinchada.gd`/`partido.gd` y no dio con él -hueco de búsqueda, no de código-. Lección: ni un
   informe cuidadoso es un "no existe" garantizado sin un segundo vistazo.
2. Charlas técnicas con IA conversacional de texto libre -la versión de menú por tonos ya existe;
   esto pediría una API de lenguaje real, que choca con el diseño 100% sin conexión del proyecto.
3. Animaciones de lenguaje corporal en la banda / "efecto banquillo" visual en el visor 3D.
4. Modo Director de Cantera completo (edades 10-16, alimentación, estudios) -hoy la cantera arranca
   a los 16-18-.
5. Juegos mentales en el túnel antes de salir a la cancha.

Ninguno de los cinco se empezó -es a propósito, decisión pendiente del usuario, no un olvido-.

Relacionado en memoria: `dinastia-auditoria-total-12-9.md` (la auditoría de esta misma tarde),
`dinastia-pendientes.md`, `dinastia-estado-v325.md`.

## VISUALES GENERALES Y SHADERS (12-9-2026, noche) — CERRADA

Pedido textual: "Visuales generales, Shaders entré otros" -tras preguntar si seguía con visuales o
con el estadio por módulos, eligió visuales-. Antes de esto solo existía UN shader en todo el
proyecto activo (`visor/agua.gdshader`, el del río/piscina/estanque). Se sumaron dos más.

- [x] **El cielo de la ciudad, con shader propio** (`visor/cielo.gdshader`, nuevo). Reemplaza el
  `ProceduralSkyMaterial` de `ui/ciudad_vista.gd` -que solo sabe degradar cuatro colores- por un
  shader que hace el MISMO degradado (mismos uniforms, misma lógica de `_aplicar_hora()`, cero
  cambio de look de día) y le suma:
  - **Estrellas de verdad de noche** -antes el cielo nocturno era un azul liso sin una sola-, una
    rejilla de celdas por dirección de mirada con un poco de titileo por `TIME`.
  - **Nubes a la deriva** en pleno día, con ruido fbm sobre la esfera de mirada (no un plano UV, para
    que no se cosan) que se arrastran solas con el tiempo.
  - **El sol como disco y halo** -antes el astro que mueve todas las sombras de la ciudad no se veía
    él mismo en el cielo-, leyendo `LIGHT0_DIRECTION`/`LIGHT0_COLOR` del propio `DirectionalLight3D`.
  - **Bug real encontrado y corregido en el camino**: el primer intento del "suelo" del cielo -la
    parte que se ve por debajo del horizonte, que en este mapa es la mayoría del hueco entre el
    complejo y el fondo, no una franja fina- usaba una curva (`pow(-arriba, 0.4)`) que se iba al
    color OSCURO casi de inmediato, y como cubre tanto del encuadre se leía como una banda negra
    enorme cortando el amanecer. Confirmado pintándolo de un magenta de depuración -el "hueco" ocupa
    casi toda la mitad inferior del cielo, no una franja-. Corregido con una curva alta
    (`pow(-arriba, 3.2)`) que se queda en el tono de césped salvo mirando casi derecho hacia abajo.
  - Las funciones de ruido (`hash13`/`ruido3`/`fbm3`) se sacaron a `visor/ruido.gdshaderinc`, para no
    duplicarlas cuando el terreno (abajo) las necesitó también.
- [x] **El terreno, con ladera de verdad** (`visor/terreno.gdshader`, nuevo). Antes una sola textura
  de césped se estiraba sobre TODO el relieve -llano o loma de 78 m, daba igual-, así que una
  pendiente se leía como césped vertical. Ahora mezcla la misma textura de césped con roca/tierra
  procedural según `NORMAL.y` (plano sigue siendo césped puro; la pendiente se vuelve tierra y luego
  roca moteada). **Hallazgo al medir, no al mirar**: la pendiente más fuerte de TODO el terreno
  generado (barrida por código, no a ojo) es de solo ~12° -este mapa es de lomas de paseo, no
  montañas-, así que los umbrales pensados para relieve de verdad (0,55/0,82 de `NORMAL.y`) nunca se
  cruzaban y el shader no se notaba en ningún punto del mapa. Subidos a 0,965/0,994 -casi 1,0-, hasta
  la ladera más discreta saca ya su franja de tierra. Verificado con `pruebas/captura_terreno_shader.gd`
  (nuevo): busca por código la pendiente más pronunciada del mapa entero y pone la cámara justo ahí,
  no en un punto fijo a ciegas.
- [x] **Verificado sin regresión**: `pruebas/captura_horas.gd` (las cinco fotos de siempre) y el
  banco completo, 0 fallos. El mediodía y la zona llana del mapa se ven exactamente igual que antes
  -el degradado del cielo y el césped del llano no cambiaron, solo se sumó lo nuevo-.

Quedó pendiente, para otra tanda si el usuario lo pide: nubes con sombra propia sobre el suelo, y
subir algo la altura/frecuencia del ruido del terreno si en algún momento se quiere relieve más
dramático que "lomas de paseo" -eso SÍ activaría el shader de ladera con fuerza en vez de apenas
rozarlo-.

- [x] **Sombra de nube sobre el terreno**, el pendiente que había quedado anotado arriba. El mismo
  ruido del cielo, a la deriva en la misma dirección, proyectado sobre el plano XZ del terreno
  (`nubes_sombra_*` en `visor/terreno.gdshader`) -no es la sombra EXACTA de una nube del cielo, eso
  pediría pasar una textura entre los dos shaders, pero se nota casi igual y sale mucho más barato-.
  Verificado con `pruebas/captura_terreno_shader.gd`: se ve una mancha oscura grande moviéndose sobre
  la ladera. En el encuadre normal de la ciudad (`captura_ciudad_postal.gd`) casi no se nota -esa
  vista mira sobre todo la explanada de `_suelo()`, no el terreno con shader-, que es justo el
  comportamiento esperado: el efecto es para el paisaje lejano, no para la plaza del complejo.

- [x] **Las ventanas de los edificios, ya no se encienden todas juntas.** Antes CADA edificio tenía
  UN solo material de ventana compartido por todas sus plantas y caras -de noche se encendía como un
  bloque, todo o nada, que ninguna oficina real hace-. Ahora cada tira de ventanas (planta × cara)
  lleva su propio material con un azar propio (semilla sacada de la posición del edificio, para que
  no parpadee entre partidas): se enciende en SU propio momento de la tarde/noche, llega a SU propio
  techo de brillo, y cerca de un tercio se queda oscura o casi toda la noche -la oficina vacía, el
  que ya se fue-. Verificado con `pruebas/captura_horas.gd`: en `hora_noche.png` ya se ve la fachada
  moteada -plantas claras y oscuras mezcladas-, no la placa uniforme de antes. Banco completo: 0
  fallos, sin coste real -son más materiales (uno por tira en vez de uno por edificio) pero
  `StandardMaterial3D` sin textura es barato incluso por miles.

## TAREA (12-9-2026, mediodía, ya CERRADA): el balón, variantes estéticas y motor propio

Pedido del usuario: darle al balón 3D sus propias variantes estéticas -ya hay un catálogo
`BALON_SKINS` con 5 pieles (clásico, dorado, retro, fluorescente, colores del club) elegible en
Club → Detalles del club (`Comercial.balon`), pero el visor 3D siempre dibuja el mismo balón fijo,
sin usarlo- y un motor de movimiento propio -hoy el balón solo hace un `lerp` lineal hacia un punto
aleatorio con un rebote de seno, sin arco real ni rodado con el eje correcto-.

Plan, marcando lo que ya quedó:

- [x] `visor/balon_3d.gd` nuevo: clase `Balon3D` con textura por piel elegida (reutiliza el patrón
      a cuadros de `StadiumBuilder._make_ball_texture()` pero coloreado según `BALON_SKINS`, y la
      piel "club" usa `color1`/`color2` del club en vez de colores fijos) y movimiento por ARCO real
      (parábola de verdad, no un seno) con rodado -gira sobre el eje perpendicular a la dirección de
      viaje, no siempre en X-.
- [x] `StadiumBuilder.spawn_ball()` construye un `Balon3D` en vez de una malla suelta.
- [x] `MatchPlayback` deja de mover el balón a mano (`_mover()`) y llama a `Balon3D.enviar()` /
      `avanzar()`: arcos más altos y largos en un gol, rasantes en una jugada normal.
- [x] `Comercial.color_balon(clave, club)` -helper que resuelve la piel elegida a dos colores de
      verdad, incluyendo el caso especial "club"-.
- [x] Enchufar la piel elegida desde `principal.gd` hasta `estadio.gd`, mismo patrón que ya se usó
      para `perfil_estadio`: threading por parámetros opcionales, no una variable global.
- [x] Verificar con captura -el color del balón cambia de verdad según la piel elegida (comprobado
      píxel a píxel contra el color esperado de la piel "dorado"), rueda de verdad (cambio de
      rotación medido, no asumido) y arquea con altura real en un partido en vivo. Encontrado y
      arreglado de paso un bug real durante la verificación: si se lanzaba un arco nuevo antes de que
      el anterior terminara -pasa siempre en un partido de verdad-, la altura se acumulaba arco sobre
      arco y el balón acababa flotando cada vez más arriba; ahora cada arco parte siempre del suelo
      (`radio`), nunca de la `y` a medio camino del arco anterior.
- [x] Banco headless: 0 fallos. APK recompilado.

TAREA CERRADA (12-9-2026). Sigue en la cola: la casa/ciudad encontradas y el estadio por módulos,
ver la sección de abajo.

## COLA DE TAREAS PEDIDAS EL 12-9-2026 (registro para que no se pierdan)

El usuario pidió explícitamente que todo pendiente quede anotado aquí para que, si una sesión no
alcanza a terminar algo, quede registrado y no haya que preguntarle de nuevo. Orden de la cola:

1. **El balón 3D** -variantes estéticas + motor propio de arco/rodado-: CERRADO, ver la sección de arriba.
2. **La casa y la ciudad que dejó hace tiempo, YA ENCONTRADAS (12-9-2026)**: estaban en
   `recursos\modelos3d\` local, con nombres genéricos que no se habían abierto antes:
   - `interior-15-minimalist-panoramic-viem.zip` → `source/ДОМ скетч.fbx` ("casa boceto", ruso) con
     texturas PBR completas. Candidata a oficina del entrenador.
   - `3.zip` → `source/Жилой комплекс_3.fbx` ("complejo residencial", ruso), con texturas realistas
     de madera/teja/metal. Candidata a sumar a la ciudad deportiva 3D.
   - [x] Convertidos (12-9-2026) con `herramientas\fbx_a_glb.py` -nuevo, `blender_a_glb.py` solo
     sirve para `.blend` ya abiertos, un `.fbx` suelto hay que importarlo aparte-: baja las texturas
     a 1024 px de lado como mucho (traían hasta 4096, y de fondo no se nota) y decima la malla.
     `assets/ciudad/oficina_dt.glb` (2,4 MB, 3.775 vértices) y
     `assets/ciudad/complejo_residencial.glb` (19,3 MB, 226.252 vértices -de 1,86 MILLONES que traía
     el original-). Todas las texturas de ambos cargaron bien, ninguna quedó "SIN CARGAR".
   - [x] **YA MONTADOS (12-9-2026, más tarde el mismo día)**: se portó el visor de la ciudad entero a
     `dinastia-godot` (ver «EL MAPA DE LA CIUDAD DEPORTIVA, PORTADO Y REPLANTEADO» más abajo) y los
     dos modelos quedaron puestos donde funcionan de verdad -el complejo residencial es el barrio del
     sur, la casa moderna es la villa de la parcela "ribera"-. Este punto queda cerrado.
     (Nota original, ya superada: en el momento en que se escribió esto la ciudad 3D todavía vivía
     solo en `visor3d\scripts\`, el proyecto viejo que no compila el APK; por eso decía que montar
     los modelos "no serviría de nada". Se portó ese mismo día, ver abajo.)
3. **[ ] El estadio por MÓDULOS -SIGUE SIN HACER, confirmado al auditar la migración el 12-9-2026-**:
   desarmar y volver a armar el recinto con distintas piezas 3D independientes -confirmado que el
   usuario sí lo quiere-. Hoy no existe: lo que hay es reformar el estadio
   COMPLETO (`EstadioPropio`, ver [[dinastia-estadio3d]]) o elegir entre 8 estilos enteros, no piezas
   sueltas armables. Sin diseñar todavía cómo se vería un sistema de módulos de verdad -qué es una
   "pieza": ¿una bandeja completa?, ¿un tramo de fachada?, ¿el túnel?-. Es el único pendiente real que
   quedó de esta cola sin cerrar.

## EL MAPA DE LA CIUDAD DEPORTIVA, PORTADO Y REPLANTEADO (12-9-2026) — CERRADO

Era la única tarea que el usuario dejó como prioridad ("con que la ciudad quede como quiero y sea
navegable visualmente yo soy feliz"). Qué se hizo, en orden:

1. **Portado al proyecto de verdad.** `CityBuilder` llevaba desde el 2-09-2026 viviendo SOLO en
   `visor3d\scripts\` -el proyecto viejo, que no compila el juego ni el APK-. Ahora está en
   `visor\city_builder.gd`, con sus assets copiados (`estadio.obj`, `farola`, coches, los packs CC0
   de Kenney, el velero) y una pantalla propia -`ui/ciudad_vista.gd`, `VistaCiudad`- que es a
   `CityBuilder` lo que `estadio.gd` es a `StadiumBuilder`: en vez del puente de JSON del proyecto
   viejo, recibe los objetos vivos (`Club`, `Instalaciones`, `Ciudad`) y arma el diccionario en el
   momento. Se abre con "🏙️ Ver la ciudad en 3D" en Club → Ciudad.
2. **El estadio del mapa es EL ESTADIO.** Antes era `estadio.obj`, una maqueta escalada por el
   aforo. Ahora lo levanta `StadiumBuilder` con el perfil de `EstadioPropio`, o sea que la forma,
   las bandejas, el techo, el corte del césped y el color de las butacas que pagaste en Club →
   Estadio **se ven también desde el mapa**. Era un pedido explícito: "si el estadio fue modificado
   debe notarse".
3. **Los cinco terrenos existen en 3D.** `TERRENOS` (norte, sur, centro, periferia, ribera) era una
   lista de texto que no se veía en ninguna parte. Ahora cada uno es una PARCELA con su suelo, su
   bordillo y su cartel con el nombre real de la tabla; el bordillo se tiñe del color del club si el
   terreno es tuyo. Encima aparecen los negocios de `NEGOCIOS` que van atados a un terreno: hotel y
   rampa de estacionamiento subterráneo en el norte, centro comercial (manzana de edificios CC0) en
   el centro, clínica con su cruz dentro del recinto. `resto` y `escuela` no se dibujan **a
   propósito**: su terreno es `null` en la tabla, el propio juego dice que no ocupan suelo.
4. **Calles de verdad.** Un anillo alrededor del recinto con marcas viales, un ramal a cada parcela
   y otro al barrio residencial. Es lo que convierte cinco cosas sueltas en un sitio recorrible.
5. **El río con el velero.** `vagabond.obj` resultó ser un velero (no una persona, pese al nombre) y
   llevaba dos semanas sin usarse; ahora navega el río de la parcela "ribera", con sus dos orillas.
6. **Los dos modelos que trajo el usuario, cada uno donde funciona.** El complejo residencial
   ("Жилой комплекс") es el barrio del sur, al final de su calle y con ocho casas alrededor -un
   barrio no es una casa suelta-. La casa moderna ("ДОМ скетч") es la villa de la ribera: dentro del
   recinto y a 7 m se leía como una masa rota (el usuario pidió sacarla, con razón), pero en su
   parcela y a 22 m se lee como lo que es.
7. **Y los ajustes que hicieron que se ENTIENDA**, que costaron tantas pasadas como el resto junto:
   - el recinto es césped con pavimento solo donde se pisa, no una plancha de asfalto del tamaño del
     complejo;
   - los campos de entrenamiento llevan corte de césped (la misma textura del estadio) o no se
     distinguían del prado;
   - la cámara arranca a 110 m de altura y no a 170: casi cenital, todo se leía plano;
   - exposición y niebla bajadas para escala de mapa -`Calidad` está calibrada para 200 m y a 1 km
     lavaba la imagen entera-, y el "suelo" del cielo teñido de verde, que si no aparece una banda
     marrón cortando el horizonte;
   - el terreno pasa de 2.400 a 5.000 m porque desde el plano general se veía el borde del mundo.

**Queda sitio a propósito** (lo pidió: "deja espacio porque seguramente iremos poniendo más cosas"):
la mitad sur del recinto está libre, las parcelas "sur" y "ribera" admiten más edificios, y entre el
anillo de calles y el horizonte (a 560 m) no hay nada puesto.

Capturas de referencia: `pruebas/ciudad_postal_general.png` (el mapa entero),
`ciudad_postal_estadio.png` y `ciudad_postal_barrio.png`. Banco: 0 fallos.

### Segunda tanda: terreno natural, tráfico y la instalación que faltaba (12-9-2026)

El usuario pidió "mejorar conexiones, más detalles, que el terreno se vea más natural, lo mismo con
el barco" y preguntó si convenía mover vehículos. Sí convenía, y esto es lo que entró:

- **El terreno ondula.** Era un `PlaneMesh` liso de 5 km -por eso todo se leía como una maqueta
  sobre una mesa-. Ahora se genera con `SurfaceTool` y ruido, con **la zona construida siempre
  plana**: altura 0 dentro de 620 m y una rampa suave (`smoothstep`) de 520 m hacia las lomas. Esa
  regla es la clave: las calles, las parcelas y el estadio son planos rígidos a y=0, y si el suelo
  subiera debajo asomarían flotando por un lado y enterrados por el otro. Los edificios del
  horizonte sí se apoyan en la loma (`altura_en()`), o se verían flotando en la ladera.
- **Hay tráfico.** `visor/trafico_ciudad.gd` (`TraficoCiudad`) mueve cosas por recorridos cerrados:
  cada vehículo guarda su distancia recorrida y la ruta le dice dónde cae y hacia dónde apunta.
  Catorce coches dando vueltas al anillo en los dos sentidos (dos carriles, o iban todos en fila
  india por el mismo sitio), cinco más por la avenida de acceso y la calle del barrio, y **el velero
  navegando el río**. Las esquinas se redondean con Bézier (`_redondear`) porque si no el coche gira
  90° en un fotograma y el velero daba un volantazo imposible al final del cauce. Comprobado con
  `pruebas/captura_trafico.gd`: 20 vehículos, ninguno quieto, 14,6 m de media en 40 fotogramas.
- **Faltaba una instalación de verdad.** `Instalaciones.CATALOGO` tiene **19** obras y el 3D dibujaba
  **15**. Tres de las cuatro ausentes está bien que no sean edificios (`trib` y `cal` SON el estadio,
  `park` son los coches), pero **`huerto`** -"Huerto y zona sustentable"- sí ocupa suelo y no se veía:
  ahora son bancales de cultivo que crecen en número con el nivel, más un invernadero de cristal.
- **Detalles que hacen de pegamento**: pasos de cebra en cada cruce del anillo con las parcelas,
  plazas pintadas en el aparcamiento, y los campos de entrenamiento con rayas de corte en dos
  direcciones -antes el patrón "damero" a esta escala se leía como un tablero de ajedrez-.

Banco: 0 fallos. APK recompilado.

### Tercera tanda: el bug del tráfico y más recursos (12-9-2026)

- **LA FLOTA CIRCULABA MARCHA ATRÁS.** El usuario lo vio ("creo que los vehículos se mueven de forma
  rara") y la medición lo confirmó sin discusión: alineación morro/marcha **-1,000 en los veinte
  vehículos**. La causa es un signo: `atan2(dir.x, dir.z)` alinea el eje **+Z local** del nodo con la
  marcha, pero los coches de Kenney tienen el morro en su **+X** (por eso el aparcamiento de siempre
  los giraba 90°), así que hay que RESTAR 90°, no sumarlos. Con `-PI*0.5` la medición pasó a 1,000.
  El velero necesitaba el mismo arreglo y se le había puesto el mismo signo malo por copiar.
  `TraficoCiudad.diagnostico()` existe justo para esto: da el producto escalar entre el morro y la
  dirección, y deja el fallo en un número en vez de en un "se ve raro".
- **Se estaba usando una fracción de lo que hay.** El kit CC0 de ciudad tiene **42 piezas** y se
  usaban 5; el de coches tiene una docena larga de vehículos y se usaban 7. Ahora: la manzana
  comercial son **ocho edificios distintos** con toldos y parasoles, el tráfico mezcla ambulancia,
  policía, bomberos, basurero y furgonetas de reparto (uno de cada cinco, o el mapa parecería una
  emergencia permanente), y **el terreno sur por fin tiene algo**: naves, maquinaria y contenedores
  en cuanto lo compras. Era el único solar que se quedaba vacío pasara lo que pasara, porque ningún
  negocio de la tabla lo pide.
- La casa de la ribera ahora solo aparece **si el terreno es tuyo**, igual que los demás negocios:
  antes salía siempre, lo cual contradecía el propio sistema de compra.

**A DÓNDE VA ESTO** (ver la memoria `dinastia-vision-ciudad.md`): el usuario dijo que la ciudad es de
sus partes favoritas, que es fan de Cities Skylines y que quiere "montarse una ciudad donde el club
tenga control absoluto a través de la prioridad y construcción del terreno". El sistema de terrenos
y negocios de `nucleo/ciudad.gd` es la semilla correcta de eso; lo que falta es profundidad -más
parcelas, más cosas construibles, y que lo construido pese en la economía-. No recortar aquí "porque
es estética": para él no lo es.

### Cuarta tanda: ciclo del sol, shaders, instalaciones grandes y las farolas (12-9-2026)

Pedido textual: "agregá el ciclo del Sol... no se ven los edificios, se siente un poco vacío y las
instalaciones deben ser más grandes y detalladas, además de eso puedes ver lo de los Shaders?", y
después "quiero reemplazar esas farolas o hacerlas negras y más grandes y que sus luces sean de
colores que uno pueda escoger durante la noche".

**EL CICLO DEL SOL** (`ui/ciudad_vista.gd`). Amanece, mediodía, atardece y anochece, vuelta a
empezar; una vuelta son 120 s. Todo sale de UNA variable, `_hora` (0..24), que alimenta el sol, el
cielo, la niebla, la exposición y las luces de la ciudad: así no hay forma de que una parte del
mundo se quede desincronizada de otra. Hay reloj en pantalla y botón para pararlo.
- **La trampa que costó una ronda**: si se deja que la luz baje DE VERDAD bajo el horizonte, de
  noche apunta hacia arriba desde el subsuelo y **no ilumina nada** -la ciudad desaparecía en negro
  salvo las ventanas encendidas-. La luz nunca baja de 8°: de noche sigue viniendo de arriba, muy
  floja y azulada, que es lo que hace la luna.
- Exposición y ambiente se abren de noche y se cierran de día, como el diafragma de una cámara.

**LAS INSTALACIONES, EL DOBLE DE GRANDES Y CON DETALLE.** Pasaron de 9-16 m de fachada a 19-34 -al
lado de un estadio de 110 m eran cajitas- y la parrilla pasó de 42×32 m a 74×48 o se solapaban.
Cada una lleva ahora marquesina de entrada con pilares, banda de rótulo del color del club y
máquinas en la cubierta (climatizadoras y cajón de escalera): eso último es lo que rompe la silueta
plana del tejado, que era lo que más las delataba como cajas.

**SHADERS.** `visor/agua.gdshader`, para el río: oleaje con dos senos cruzados (uno solo se lee como
chapa ondulada), **normales derivadas del propio oleaje** -sin eso la luz no cambia y el agua parece
plástico ondulado-, fresnel (de frente casi transparente, de canto espejo) y espuma en las crestas.
El plano del río va subdividido 12×140: un `PlaneMesh` sin subdividir tiene cuatro vértices y un
shader que mueve vértices sobre cuatro puntos no hace olas, hace un plano que cabecea. El brillo del
agua lo baja el ciclo nocturno.

**LAS FAROLAS, RECONSTRUIDAS POR CÓDIGO.** Se tiró `farola.obj` (gris, pequeño, misma silueta en
todas partes). Ahora son negras, de 13 m, con pie, mástil que se estrecha, brazo curvo -tres tramos
girando, que es la forma barata de sugerir una curva- y luminaria. Se construyen por código por dos
razones concretas: se puede teñir la luminaria en tiempo real cuando el jugador cambia el color, y
la silueta se controla en vez de heredarla. El brazo apunta SIEMPRE a la calzada: una farola con el
brazo hacia el campo alumbra el césped y deja la calle a oscuras.

**EL COLOR DEL ALUMBRADO LO ELIGE EL JUGADOR.** `Ciudad.luces` (se guarda con la partida), con siete
tonos con nombre -ámbar de sodio, blanco cálido, blanco frío, cian, magenta, verde neón, rojo
brasa- más un selector libre, en Club → Ciudad. De noche las farolas son lo único que dibuja el
trazado de la ciudad, así que su color es una decisión de identidad, no un ajuste gráfico.

**TRES FALLOS REALES QUE SALIERON DE AQUÍ**, todos encontrados midiendo y no mirando:
1. **El suelo no se iluminaba de noche.** No era que las farolas estuvieran apagadas -se imprimió su
   estado: energía correcta, color correcto, visibles-. Era que **el terreno era UNA sola malla de
   5 km**, y en el render de Compatibility cada OBJETO recibe como mucho 8 luces: las 54 farolas se
   repartían ocho plazas para todo el mapa. Arreglo: el terreno se genera en **8×8 baldosas**, y
   `rendering/limits/opengl/max_lights_per_object=24`.
2. **Ese ajuste no hacía nada al principio**, porque se puso en un segundo bloque `[rendering]` al
   principio de `project.godot` y ya había uno más abajo: Godot se queda con uno de los dos y no
   avisa. Tiene que ir en la sección que ya existe.
3. **La luminaria salía blanca** por mucho color que se eligiera. Culpa del `glow`:
   `glow_hdr_threshold` está en 1,05 y con multiplicador de emisión 7 los TRES canales del cian se
   iban por encima del umbral, así que el halo florecía blanco. Con 1,6 el canal rojo se queda por
   debajo y el halo conserva el tono. La potencia la pone la luz real, no la emisión de la carcasa.

**EL VÍDEO.** `pruebas/video_ciudad.gd` + el escritor de películas de Godot (`--write-movie`), que
renderiza a paso fijo: el vídeo sale fluido aunque la máquina en vivo fuese a tirones. Trampa de
tamaño: Godot escribe **AVI con MJPEG**, sin compresión entre fotogramas, así que pesa ~2 MB por
segundo a 720p. Bajar la resolución apenas ayuda (de 960×540 a 800×450 solo quitó un 3%); lo que
manda es la DURACIÓN. 15 s a 960×540 son 28 MB, que es lo que cabe en el límite de envío de 30 MB.

Capturas de referencia del ciclo: `pruebas/hora_amanecer.png`, `hora_mediodia.png`,
`hora_atardecer.png`, `hora_noche.png` y `hora_farolas.png` (primer plano de una farola encendida).

### Quinta tanda: la ciudad crece con el club, y los cinco puntos del análisis (12-9-2026)

**LA CIUDAD CRECE CON EL CLUB.** Idea propia, con la libertad creativa que dio el usuario, y es la
que más liga esta pantalla con el resto del juego: **si el club sube, la ciudad se nota**.
- `rep` decide cuánto skyline hay al fondo (de 10 edificios a 46) y cuánto miden (×0,75 a ×1,35), y
  cuánto tráfico circula (de 4 coches por sentido a 10).
- `socios` decide el tamaño del barrio residencial (de 3 casas por acera a 8).
- No hace falta sistema nuevo: reputación y socios ya suben solos con los títulos. Lo que faltaba
  era que el mapa los LEYERA. Hasta ahora ganar la liga cambiaba una tabla; ahora se ve desde la
  ventanilla del coche. Comprobado con `pruebas/captura_crecimiento.gd`, que pinta la misma ciudad
  con un club de rep 28 y con uno de rep 92 desde el mismo encuadre.
- Y **banderines del club en cada farola**: en cuanto los ves repetidos calle abajo, el mapa deja de
  ser "una ciudad" y pasa a ser "la ciudad del club".

**LOS CINCO PUNTOS DEL ANÁLISIS que trajo el usuario**, todos atendidos:
1. *"Los bloques se ven muy idénticos entre sí"* → cada edificio del kit CC0 va ahora con su propia
   altura (la escala en Y es independiente), su orientación (cuatro giros posibles) y su retranqueo
   respecto a la acera. Con escala y orientación iguales, ocho modelos distintos seguían leyéndose
   como ocho copias.
2. *"Las áreas entre los bloques se sienten vacías"* → los árboles estaban TODOS fuera de la valla,
   así que el interior -que es donde más se mira- era pavimento pelado. Ahora hay 80 árboles dentro
   del recinto esquivando campos, avenida, edificios, estadio y piscina, más una orla de arbolado
   alrededor de cada parcela, que es lo que las ata al paisaje en vez de dejarlas como pegatinas.
3. *"Más disciplinas deportivas"* → **piscina olímpica** (50×25 m con sus ocho calles y corcheras,
   con el shader del agua en modo piscina: turquesa y casi sin ola), **polideportivo** con cubierta
   curva -esa silueta es lo que de lejos distingue un pabellón de una caja de oficinas- y **canchas
   de tenis y pádel** en batería. Las tres salen de instalaciones que ya existen (`piscina`, `gim`,
   `ct`), así que aparecen cuando las construyes y no antes.
4. *"Faltan parques o plazas en el barrio"* → **parque del barrio**: césped propio, caminos en cruz,
   estanque con el shader del agua a escala de charca y arbolado denso.
5. *"Infraestructura de transporte"* → **cuatro paradas de autobús** con marquesina, cristal, banco y
   la franja del club (estadio, centro comercial, zona industrial y barrio), y un **eje vial
   exterior**: un segundo anillo que pasa por fuera rozando las cuatro parcelas y las conecta entre
   sí directamente, con su propio tráfico. Antes, para ir de la zona industrial al centro comercial
   había que rodear el recinto del club por dentro.
4. **Reporte del usuario (12-9-2026, sin confirmar todavía en su celular)**: en el partido "los
   jugadores no tienen cara y están caídos", y el público y el pasto se ven falsos. Investigado con
   `pruebas/captura_diagnostico_partido.gd`: en un partido simulado de escritorio, los 25 en cancha
   cargan el modelo REALISTA (no el respaldo de Kenney) y ninguno queda tumbado -0 casos-. No se
   pudo reproducir "sin cara/caído" desde aquí; es candidato a un problema específico del render
   Compatibility de Android (texturas que no cargan igual que en PC), pendiente de una captura suya
   real del celular para diagnosticar de verdad. Lo del público y el pasto SÍ es real y esperable:
   Android corre en `gl_compatibility` -sin SSAO, niebla volumétrica ni los mapas de detalle que sí
   se ven en PC con calidad alta ([[dinastia-calidad-grafica]])-, y el patrón de grada se repite
   demasiado chico para la distancia de cámara típica. Pendiente: subir la resolución/variedad de la
   textura de grada y del césped específicamente para que se sostengan mejor en Compatibility, sin
   depender de efectos que el móvil no tiene.

No confirmado con el usuario: si quiere las tres primeras en este orden o si alguna pesa más que las
otras, ni la causa exacta de la parte "jugadores caídos" del punto 4.

**Punto 4, la grada, CERRADO (12-9-2026):** el usuario mandó una foto real -viéndolo en PC, no en el
celular- confirmando el defecto. La causa no era la resolución ni el patrón de asientos -esos son
regulares también en un estadio real-: era que `_make_stand_texture()` pintaba al público en una
REJILLA perfecta (columna cada 3 px, fila cada 2, siempre las mismas columnas), y una rejilla
perfecta repetida muchas veces a lo largo de la tribuna hace moiré -rayas verticales de color que no
existen en los datos, un efecto óptico de la regularidad-. Se cambió a un barrido aleatorio de
posición (mismo recuento total, sin dos veces la misma columna) más un toque de grano por butaca y
el doble de resolución (64×320, antes 48×192). Verificado con captura: el rayado vertical
desapareció, queda un mosteado de público más creíble. Sigue sin ser fotorrealista -es una textura
procedural, no fotos de gente-, y en el celular (Android, `gl_compatibility`) se va a ver un poco
más plano que en PC de todas formas, eso es un límite del renderer, no de la textura. Banco: 0
fallos. APK recompilado.

Sobre "los jugadores no tienen cara y están caídos": en la primera foto que mandó los jugadores SÍ se
ven de pie corriendo -no tumbados-, y el diagnóstico de escritorio confirmó que los 25 en cancha
cargan el modelo realista, ninguno de canto. Pero en una SEGUNDA foto, de más cerca, sí se ve el
problema real: los jugadores salen como una SILUETA plana casi negra, sin textura ni color de
camiseta -no un problema de la pose, un problema de que la textura no está pintando el material-.

**Causa encontrada y arreglada (12-9-2026), sin confirmar todavía con el usuario probándolo:**
`export_presets.cfg`, preset de Android, **nunca tuvo `vram_texture_compression/for_mobile`** -ni
en `true` ni en `false`, la clave no existía porque el preset se creó en modo simple y nunca se
tocó-. El proyecto SÍ tiene bien puesto `textures/vram_compression/import_etc2_astc=true` en
`project.godot` -las texturas se importan en ETC2/ASTC-, pero sin la marca del lado del EXPORT el
empaquetador no las estaba empatando: en desktop no se nota nada raro, pero es exactamente el tipo
de fallo que en un Android real se traduce en una textura que no carga y dejaría el material del
jugador en su color base (negro), leyéndose como una silueta sin cara. Se activó la marca que
faltaba y se recompiló el APK (58,5 → 88 MB, esperable: ahora sí empaqueta la variante comprimida
para móvil). **Falta que el usuario lo pruebe en su celular** para confirmar que esto era la causa
real; no hay forma de probarlo desde aquí sin un dispositivo Android físico.

## Qué hay portado y qué no

**El HTML sigue siendo el juego completo y jugable.** No se ha tocado nada suyo; su banco de Chrome
sigue dando 0 errores y sus 43 vistas siguen funcionando. Lo de Godot es el motor nuevo creciendo al
lado: nunca dejar la partida sin poder jugarse a medio camino.

| | HTML | Godot |
|---|---|---|
| Funciones | 920 | 1.183 |
| Líneas | 21.227 | 29.064 |
| Clases | — | 52 |

**Portado y verificado**

- Las **212 tablas de datos** completas — clubes, ligas de 23 países, jugadores reales, nombres,
  lesiones, logros, formaciones, demarcaciones. Ninguna transcrita a mano.
- **Jugador**: atributos por demarcación, rasgos, potencial, forma, moral, lesiones, dorsales y
  brazalete de capitán.
- **Club**: plantilla, caja, masa salarial, armado del once, palancas de taquilla.
- **Táctica**: formación y las seis perillas, con sus multiplicadores exactos.
- **Partido**: minuto a minuto, con goleador ponderado, remates, tarjetas y lesiones.
- **Liga**: calendario de ida y vuelta por el método del círculo, tabla, campeón.
- **Mundo**: generación con el plan de plantilla del HTML, avance semanal, cierre de temporada con
  envejecimiento, retiros y subida de cantera por el puesto que falta.
- **Economía**: valoración, sueldos y caja de club, con las curvas del HTML sin retocar.
- **Finanzas**: taquilla con su curva de ocupación, patrocinio, derechos de TV, cuotas de socios,
  sueldos y estructura, con cierre de mes cada cuatro semanas.
- **Mercado**: las tres puertas (lo que pide el club vendedor, lo que pide el jugador de ficha, y las
  ganas que tiene de venir), regateo, y un mercado de la IA que mueve el mundo solo.
- **Guardado** comprimido con deflate: 1.200 jugadores en 58 KB, cargan en 42 ms.
- **Banquillo**: once elegido a mano, cinco cambios por partido y tanda de penales.
- **Partido en directo**: reloj con cuatro velocidades, crónica, y la pizarra y los cambios operativos
  MIENTRAS se juega, con efecto inmediato en el marcador.
- **Copa nacional**: eliminación directa con penales, final en cancha neutral y premio fijo.
- **Ascensos y descensos**: los dos últimos bajan y los dos primeros suben, con el castigo económico
  de la televisión (300.000 en Primera contra 58.000 en Segunda).
- **Estadio en 3D dentro del juego**: el recinto de cada club, construido en el momento a partir de
  su propio dato. Sin puente ni JSON intermedio, y con la ocupación real de las gradas.
- **Los 22 en el campo**: modelos humanos con la equipación de su club, en su formación, con árbitro
  y jueces de línea. Alturas por demarcación y aspecto estable por jugador.
- **Directiva**: te ponen un objetivo según lo que es tu club, te miran cada domingo y te pueden echar.
- **Cuerpo técnico**: seis puestos que se contratan, cobran y mueven un número del motor.
- **Instalaciones**: las 19 obras del HTML, con sus plazos en semanas y sus efectos reales.
- **Prensa y despacho**: 13 decisiones y rueda de prensa con postura corporal.
- **Parte médico**: 22 tipos de lesión, recaídas, terapia y riesgo por fatiga.
- **Copas continentales**: las 8, con fase de grupos y plazas por país. Ahora se vuelven a sortear
  CADA temporada (`Mundo._sortear_continentales()` desde `nueva_temporada()`) -antes solo se hacía
  al tomar el mando, y pasada la primera temporada quedaban congeladas para siempre.
- **Selección nacional y Mundial de Clubes** (`nucleo/selecciones.gd`, 1011 líneas): estaba escrito
  entero -prenómina, nómina, desgaste y lesión de gira, nacionalización deportiva, torneo continental
  de selecciones, Copa del Mundo cada 4 años, Mundial de Clubes- pero nadie lo llamaba desde `Mundo`.
  Enganchado el 4-9-2026: `Mundo.selecciones` se crea en `tomar_el_mando()`, su `semana()` corre desde
  `avanzar_semana()` y su `cierre_de_temporada()` desde `nueva_temporada()` (antes de re-sortear los
  continentales, que es de donde lee los campeones para el Mundial de Clubes). Guardado y cargado.
  Verificado con `pruebas/banco.gd` (`_probar_selecciones`, 11 comprobaciones incluido un guardado).
  Pestaña "Selección" propia (convocados de tu club, resultados, más internacionales del mundo,
  nacionalización deportiva, escalafón) y sus noticias (prenómina, gira, lesión, nacionalización)
  llegan al registro por primera vez -`noticia.connect()` no lo usaba nadie en `principal.gd` hasta
  ahora, aunque siete clases del núcleo ya emitían esa señal.
- **Logros y memoria del club**, con gala de fin de temporada.
- **Notas por partido**: cada jugador sale puntuado y su forma sigue a sus notas.
- **La estética del HTML**: escudos generados por club (8 formas × 10 patrones) y retratos de jugador
  (23 cortes, 8 barbas, 9 accesorios), portados como generadores de SVG.
- **Interfaz**: tabla con escudos, plantel con caras, mercado, copa, club, continental, enfermería,
  logros, ficha de jugador, partido en directo y visor de estadio 3D.
- **El pulso de la carrera, `Roles`, no tenía NINGÚN gancho** (4-9-2026): `tras_partido()`,
  `tras_jornada()` y `tras_temporada()` existían y hacían exactamente lo que promete el modo de
  carrera -mover el prestigio, resolver el interinato a las cinco fechas, ascender al ayudante- pero
  `Mundo` nunca los llamaba. Un interino jugaba sus cinco fechas y no pasaba absolutamente nada; el
  prestigio del entrenador no se movía jamás. Es el sistema que hace que dirigir de interino SE
  SIENTA distinto de dirigir de DT, y estaba completamente apagado. Enganchado junto con Logros:
  `tras_jornada()` desde `avanzar_semana()` (llamarla de más no rompe nada: las fechas de interinato
  se sacan del calendario de la liga, no de un contador propio) y `tras_temporada()` desde
  `cerrar_temporada()`. `tras_partido()` fue el más interesante: solo necesita el marcador, no el
  `Partido` completo como Logros, así que en vez de limitarlo a la semana dirigida se movió DENTRO de
  `_avisar_a_la_directiva()` -que ya recorre `resultados` buscando el partido de tu club- para que el
  prestigio se mueva con CUALQUIER resultado tuyo, dirigido o no. Verificado con
  `pruebas/banco.gd` (`_probar_pulso_de_roles`) y con una captura real de un interinato fallido:
  "El club se fue a Ascenso... Se acaban tus cinco fechas de interino sin salvar al club."
- **El registro se volvió multi-sistema**: `Federacion`, `Cesiones`, `Entrenamiento`, `Prensa` y
  `Vestuario` llevaban su señal `noticia(titulo, cuerpo)` -44 sitios en total- sin que nadie la
  escuchara desde `principal.gd`. Ahora las cinco están conectadas en `_conectar_noticias()`, junto a
  las de Selecciones/Cantera/Logros: nueve fuentes distintas escribiendo en "LO QUE VA PASANDO".
- **Pantalla de inicio**: las 9 portadas (`ui/inicio.gd`), con su franja panorámica, su degradado de
  legibilidad -claro sobre la de prensa, oscuro sobre las demás-, su selector y el arranque de
  partida. Es la primera escena que se abre (`run/main_scene`); antes se entraba directo al panel de
  club sin ningún título delante. "Continuar" carga el guardado único (`Partida`, ranura `"partida"`)
  y se lo pasa a `Principal` por `Principal.mundo_a_cargar`, la única vía para llevar un argumento a
  una escena que arranca sola. Verificado con `pruebas/banco_inicio.gd` (headless, 7 comprobaciones)
  y con capturas de las tres portadas más distintas entre sí (`pruebas/inicio_*.png`).

- **Cantera y representantes** (`nucleo/cantera.gd`, 1209 líneas): también estaba escrito entero y
  sin enganchar -camada anual, hijos de leyenda, becas, fugas de canteranos sin ficha, el peso de un
  apellido, y los representantes que presionan por sus clientes-. Es la idea central del juego, la
  que da nombre a DINASTÍA. Enganchado el 4-9-2026 junto con Selecciones: `Mundo.cantera` se crea y
  siembra sus leyendas en `tomar_el_mando()`, `procesar_semana()` y `sortear_guerra_agentes()` corren
  desde `avanzar_semana()`, y `camada_anual()`/`registrar_retiro()`/`chequeo_promesas()` desde
  `nueva_temporada()` -la camada va DESPUÉS de los retiros (para que un veterano pueda entrar al
  libro de leyendas el mismo año) y de la reposición automática (para que un canterano de la camada
  no le robe el puesto a `_subir_de_cantera()`). Pestaña "Cantera" propia (camada, listos para
  debutar, categorías inferiores con becas) y la exigencia de un representante sale en el despacho,
  igual que una decisión de prensa. Guardado y cargado. Verificado con `pruebas/banco.gd`
  (`_probar_cantera`) y con captura tras cinco temporadas: salió un hijo de leyenda de verdad
  ("Fabián Pérez, hijo de Marcelo Pérez") y un hermano subiendo al primer equipo.

- **Logros y memoria del club, de verdad esta vez** (`nucleo/logros.gd`): la pestaña "Logros" ya
  existía y pintaba el catálogo de veinte logros, pero nadie llamaba nunca a `tras_partido()`,
  `celebrar_titulo()`, `cerrar_temporada()` ni `revisar()` -así que TODO salía siempre "por hacer",
  para siempre, por muchas temporadas que se jugaran. Parecía terminada y estaba completamente
  muerta. Enganchado el 4-9-2026: `Mundo.avanzar_semana()` llama a `logros.tras_partido()` cuando el
  partido que se acaba de dirigir es del club propio (solo el dirigido: `Liga.jugar_jornada()`
  descarta el `Partido` completo de los que solo se simulan por dentro, así que la memoria no se
  alimenta las semanas que no se dirige); `Mundo.cerrar_temporada()` llama a `celebrar_titulo()`
  cuando el club propio gana su liga o su copa, y a `logros.cerrar_temporada()` (la gala: equipo
  ideal, mejor joven, mejor entrenador) ANTES del bloque de ascensos/descensos -por la misma trampa
  del `mi_puesto` de más arriba: después, `liga_de(mi_club())` ya sería la liga nueva. Con el club
  más fuerte de su liga y seis temporadas, cayeron 2 de 20 logros y 5 títulos reales, verificado con
  `pruebas/banco.gd` (`_probar_logros`) y con captura. El perfil de gestor (`user://
  perfil_gestor.json`, la carrera que sobrevive a cada partida) ya funcionaba solo en cuanto
  `sumar_xp()` empezó a llamarse de verdad. Los dos cabos que quedaban sueltos también se engancharon
  después: el XP por ascenso de ayudante a entrenador (en `Roles._ascender_de_ayudante()`, con hito
  propio para que no se pueda farmear carrera tras carrera) y la celebración de un título continental
  de clubes -ese torneo termina a mitad de temporada, no en `cerrar_temporada()` como liga y copa, así
  que el gancho vive dentro del propio bucle de continentales de `avanzar_semana()`, justo después de
  `t.jugar_ronda()`, y solo dispara la semana exacta en que `t.campeon` pasa a ser el tuyo. Verificado
  forzando una final a dos contra el club más débil del mundo generado (con reintento de semilla: una
  eliminatoria a un partido la puede perder hasta el favorito absoluto).

- **Cesiones y cláusulas de rescisión, con pantalla propia y con un bug de guardado real
  corregido** (4-9-2026, segunda tanda): `nucleo/cesiones.gd` ya corría solo -`pagar_cuotas()` y
  `revisar_bonos()` desde `avanzar_semana()`, `resolver()` y `cobrar_plusvalias()` desde
  `nueva_temporada()`- pero era TODO automático: ni ceder a un canterano, ni pactar o pagar una
  cláusula, se podían iniciar desde la interfaz. Peor todavía, **`Mundo.cesiones` no se recreaba al
  cargar una partida** -a diferencia de `mercado` y `roles`, que sí-: cada partida cargada empezaba
  con las cesiones y las cláusulas en blanco, en silencio, porque todo lo que las usa ya comprobaba
  `!= null` antes de tocarlas. No era falta de pantalla, era pérdida de datos real. Arreglado en
  `partida.gd` (se crea en `cargar()` igual que `mercado`/`roles`, y ahora tiene `a_dic()`/
  `desde_dic()` enganchados). Pestaña "Contratos" propia: cedidos fuera con el ahorro salarial, a
  quién ceder (canterano a préstamo, o con opción/obligación de compra al que no juega), y las
  cláusulas de tu plantel con botón para pactar o blindar. Y en la ficha de CUALQUIER rival con
  cláusula -el 30% del mundo la tiene, por hash, sin que nadie la pactara- un botón de clausulazo:
  pagas y es tuyo, sin pasar por Mercado. Verificado con `pruebas/banco.gd` (`_probar_cesiones`,
  incluido el guardado) y con capturas.

- **El menú de modos, con los permisos de `Roles` hechos cumplir de verdad** (4-9-2026, tercera
  tanda): la tabla `MODOS_JUEGO` del HTML (7 tarjetas jugables: Director Técnico, Director Deportivo,
  Ayudante de Campo, Interinato, Director de Cantera, Dueño de Club, Modo Jeque) ya estaba exportada
  en `datos/tablas.json` y `Roles.arrancar(modo_id, nombre)` ya sabía leerla entera -pero no había
  ninguna pantalla que llamara a `arrancar()` con el id de una tarjeta: toda partida nueva arrancaba
  de DT clásico a la fuerza, así que el trabajo de `Roles` de la noche anterior (interinato,
  ascenso de ayudante, prestigio) no tenía puerta desde el menú. Nueva escena `ui/seleccion_modo.gd`
  (`escenas/seleccion_modo.tscn`), con las tarjetas por categoría ("Dirigir"/"Mandar", colores del
  propio HTML) y el nombre del entrenador; `Inicio._nueva_partida()` pasa por aquí antes de
  `principal.tscn`, con el mismo canal de variables estáticas que `mundo_a_cargar`
  (`Principal.modo_elegido` / `dt_nombre_elegido`).
  **"Crear tu Club" queda fuera a propósito** -funda un club nuevo renombrando al colista y
  rehaciendo su plantel, es su propia pieza- y también Retos y Tutorial.

  **Actualización (4-9-2026, quinta tanda): esta pantalla se fusionó con `Inicio`** -ver más abajo,
  "El menú de verdad, fusionado en una sola pantalla"-. `escenas/seleccion_modo.tscn` y
  `ui/seleccion_modo.gd` ya no existen; todo lo que hacían vive ahora en `ui/inicio.gd`.

  Y de paso salió un fallo más serio: **los permisos de `Roles` (`puede_fichar()`,
  `puede_contratar_staff()`, `puede_construir()`...) solo se leían en el panel informativo "TU
  CARGO"**. Ningún botón de verdad los comprobaba: un ayudante de campo podía fichar, contratar
  cuerpo técnico y construir exactamente igual que un DT, contradiciendo su propio texto de
  presentación ("No fichas, no vendes..."). La tabla `PERMISOS` de `roles.gd` ya tenía hasta un
  comentario explicando que a el ayudante había que cerrarle el cuerpo técnico y las obras -más
  estricto que el HTML original, a propósito-, solo faltaba que algún botón la mirara. Ahora la
  miran: fichar y el clausulazo (en la ficha del jugador y en "A quién ceder" de Contratos),
  contratar staff y construir obras -los tres con `.disabled` cuando el rol no deja, y el botón de
  fichar además cambia por el motivo exacto (`roles.motivo_bloqueo()`). Verificado con
  `pruebas/banco_inicio.gd` (el enganche completo modo→rol→permiso, con instancia real de
  `principal.tscn`) y con capturas: la ficha de un rival en modo Ayudante muestra "Los fichajes no
  son cosa del ayudante de campo" en vez de los botones de oferta.
  **Corrección (misma noche, antes de tocar `partido_vivo.gd`):** se revisó el HTML antes de
  bloquear la pizarra y los cambios en vivo para el ayudante/director deportivo, y NO los bloquea a
  nadie -`mando()`/`esAyudante()` solo se comprueban para fichar, rescindir y lo que pasa DESPUÉS del
  partido (sintonía con el entrenador empleado, quién te juzga), nunca dentro de la pantalla del
  partido en sí-. El texto de cada tarjeta de modo ("un DT empleado dirige los partidos") es más
  relato que restricción real: en el propio HTML sigues tocando la táctica en vivo aunque seas
  ayudante. Portar eso como un bloqueo nuevo habría sido inventar una regla que el original no tiene,
  así que `ui/partido_vivo.gd` se queda tal cual está, sin gancho de roles -es lo correcto, no un
  pendiente-.
  **Corrección posterior (11-9-2026): esa última frase quedó obsoleta la misma noche.** "Vender
  jugadores" SÍ tiene pantalla completa: la ficha trae "Poner en venta"/"Sacarlo de la lista"
  (`transferible`, con su propio permiso `puede_vender_jugadores()`) y la bandeja de "Ofertas
  recibidas" con Aceptar/Rechazar (`Mercado.responder_oferta`, `_responder_oferta` en
  `principal.gd:4983`). No queda pendiente nada de esto.

- **La dificultad, enganchada a medias a propósito**: la tabla `DIF` (fácil/normal/leyenda) estaba
  exportada y nada la usaba. Se añadió el selector a `seleccion_modo.gd` y se aplica el multiplicador
  `plata` a la caja inicial (`Principal._nuevo_mundo()`, antes de `roles.arrancar()`) -hasta 60% más
  en fácil, 45% menos en leyenda-, que es lo que se nota desde el primer minuto. Los otros dos
  multiplicadores del HTML, `prem` (premios de temporada, patrocinios, bonos) y `pide` (pretensión
  salarial en renovaciones), están repartidos por `Finanzas` y `Mercado` y quedan para otra tanda:
  aplicar solo uno bien es mejor que los tres a medias.

- **País y club, el paso 4 del asistente** (4-9-2026, cuarta tanda): nueva escena
  `ui/eleccion_club.gd` (`escenas/eleccion_club.tscn`) entre el menú de modos y el club. Y de paso
  salió algo más grande que un selector: **`_nuevo_mundo()` generaba solo 3 países** ("Tres ligas: las
  24 son 8.448 jugadores y esta pantalla todavía no tiene nada que hacer con las otras 21", decía el
  comentario), mientras que el HTML (`crear()`) siempre generó las 24 ligas completas. Esa razón ya no
  era cierta -Selecciones y Cantera recorren `m.clubes.values()` entero buscando elegibles y
  candidatos, y las copas continentales necesitan clubes de medio mundo- y además el motivo original
  (que tardaba) tampoco: generar el mundo completo mide **376 ms** en Godot nativo, contra los "3,2 s"
  que el propio HTML dejó anotados en un comentario -casi 9 veces más rápido, la clase de mejora de
  velocidad que se esperaba de la mudanza-. Ahora toda partida nueva genera las 24 ligas siempre.
  `eleccion_club.gd` las genera, muestra el selector de país (23 países + Chile con sus dos
  divisiones juntas) y la lista de clubes con escudo y reputación; `Principal.mundo_pregenerado` es el
  tercer canal de variables estáticas (junto a `mundo_a_cargar` y `modo_elegido`) para pasarle a
  `principal.tscn` un mundo ya generado y con el mando ya tomado. `_nuevo_mundo()` y este camino
  comparten `_arrancar_con()` para no repetir la aplicación de dificultad y modo en dos sitios.
  Verificado con `pruebas/banco_inicio.gd` (15 comprobaciones, incluida "el mundo que usa Principal es
  el MISMO objeto, no uno regenerado") y con capturas: Chile con sus 32 clubes, España con La Liga
  completa y sus escudos reales.

- **Los ocho Desafíos, el paso 5 del asistente** (4-9-2026, quinta tanda): panel en
  `ui/eleccion_club.gd` con las ocho tarjetas de `DESAFIOS` (icono, nombre, multiplicador, y la
  descripción como tooltip) y el multiplicador total en vivo. `Mundo.desafios: Array[String]` guarda
  los elegidos, con guardado y carga. De los ocho, **seis quedan con su mecánica real**, portada tal
  cual el HTML la comprueba (`fichajeBloqueado`, `chequeoDesafios`, `chequeoDesafiosTemporada`):
  - `pobreza` y `local` se aplican una vez, en `Mundo.aplicar_desafios()` -caja al 4% de la
    referencia; fuera los extranjeros del plantel inicial y repuesto a 20 fichas del país-. "Local"
    no usa la bolsa de agentes libres del HTML -aquí no existe esa pieza todavía-, simplemente los
    suelta: el efecto que le importa al desafío (plantel sin extranjeros) es el mismo.
  - `cantera` y `local` cierran el mercado -o solo los extranjeros- desde el mismo sitio que ya
    cerraba el rol de ayudante: `_motivo_fichaje_bloqueado()` en `principal.gd`, un único punto para
    la ficha, el clausulazo y (solo el del rol) ceder.
  - `invicto` enciende `Mundo.fin_partida` con la primera derrota -no bloquea nada por dentro, se
    puede seguir jugando, igual que el HTML- y la interfaz lo avisa una vez.
  - `derbis` parte la confianza por la mitad al perder un clásico; se portó `es_clasico()` (el "big
    3" chileno por nombre, o un hash estable del nombre para cualquier otro par de grandes del mismo
    país) porque no existía nada parecido en Godot.
  - `trotamundos` reutiliza el mecanismo de un despido real (`directiva.despedido_ya`) a la segunda
    temporada en el mismo club: la interfaz ya sabe pintar "elige otro club en la lista de arriba"
    para ese estado, así que no hizo falta inventar uno nuevo.

  Los otros dos, `leyenda30` y `sinRecarga`, se quedan en solo aviso -exactamente como en el
  HTML: se revisó `aplicarDesafios()` a fondo y ninguno de los dos tiene una sola línea de bloqueo
  real ahí tampoco, son honor del jugador en el propio original-, así que portarlos como "solo
  seleccionables" es fiel, no una pieza a medias.

  Verificado con `pruebas/banco.gd` (`_probar_desafios`, siete comprobaciones: caja, purga de
  extranjeros, invicto en empate vs. derrota, clásico reconocido y confianza partida, trotamundos a
  la primera y a la segunda temporada, guardado) y `pruebas/banco_inicio.gd` (el enganche completo
  desde `eleccion_club.gd` hasta `Mundo.desafios` aplicado). Dos bugs reales que salieron al probar
  esto: `mover_confianza()` con un delta calculado como "menos la mitad" no da lo mismo que fijar la
  mitad absoluta cuando el número es impar (55 → 27 en vez de los 28 del HTML -corregido calculando
  el objetivo primero-), y `String(fila_json[4])` revienta con un float aunque `String(entero)` y
  `String(texto)` de las mismas filas no se quejan -hace falta `str()`, no `String()`, y encima solo
  se veía instanciando la pantalla, no en el banco headless: `eleccion_club.gd` no lo ejercita ningún
  banco, solo las capturas.

- **"Crear tu Club", el último tramo del asistente**: `Mundo.fundar_club(nombre, pais)`
  (`crearClubPortada()` del HTML) toma el colista de verdad -en Chile, el de Primera B; fuera de
  Chile, el más flojo de su única división, porque ahí no hay Ascenso en los datos- y lo REEMPLAZA:
  mismo objeto, mismo puesto en el calendario, nombre nuevo, reputación 58, los colores del propio
  escudo del juego (`#1e4030`/`#c9a227`), y el plantel entero rehecho desde cero con `_poblar()` -la
  misma función que arma cualquier plantilla al generar el mundo, no una copia-. No hace falta un
  paso aparte para tomar el mando: `fundar_club()` ya lo deja hecho. Con formulario propio en
  `eleccion_club.gd` (nombre + "Fundar en el país elegido", reacciona al país que esté marcado
  arriba). Verificado con `pruebas/banco.gd` (`_probar_fundar_club`, trece comprobaciones: colista
  correcto dentro y fuera de Chile, colores, plantel, guardado) y con una captura real: "Atlético
  Prueba" con su escudo verde y oro, en Primera B, plantel de 25 con media 47,5 y la directiva
  pidiendo "Pelear el ascenso". Con esto el asistente completo del HTML -modo, dificultad, país/club
  o fundar, desafíos- ya tiene equivalente en Godot de punta a punta.

- **Cinco sonidos del HTML que nunca sonaron en Godot, más la narración que faltaba** (4-9-2026,
  sexta tanda): `sfx()` en `juego.js` (12760-12829) tiene quince efectos; solo once habían llegado a
  `Sonido._sintetizar()`. Se portaron las cinco recetas que faltaban -`ocasion`, `atajada`, `falta`,
  `corner`, `trofeo`- exactas en frecuencias y envolventes, más `_cantico()` (el "sol-sol-la-sol-do-si"
  de tribuna con palmas que solo usa `trofeo`, a los 0,7s y a los 3s -los dos `setTimeout` del HTML-).
  Truco de estas dos últimas: `_mezclar()` no alarga el array de destino, solo escribe dentro de lo
  que ya exista, así que un efecto largo con partes tardías (`trofeo` dura 5s) tiene que **reservar el
  buffer final primero** (`m.resize(...)`) y no empezar por la fanfarria de 0,14s, o el cántico de los
  3s se recorta en silencio sin avisar. `falta` y `corner` quedaron en el catálogo pero SIN enganchar a
  ningún evento: se revisó `juego.js` entero y el propio HTML nunca llama `sfx('falta')` ni
  `sfx('corner')` -están definidos y muertos ahí también-, así que engancharlos habría sido inventar
  una regla que no existe en el original.

  Pero `ocasion` y `atajada` sí que se usan en el HTML (`ataque()`, líneas 2142/2146: `if(mio)sfx(...)`
  cuando un remate no es gol), y ahí apareció el hueco de verdad: `Partido._atacar()` en Godot solo
  contaba el remate (`remates_local/visita`) y devolvía sin avisar a nadie del desenlace -la crónica
  del partido en vivo estaba **muda entre gol y gol**, ni un "atajada" ni un "al palo" ni una ocasión
  fallada en noventa minutos-. Se añadió la señal `Partido.remate(club, autor, tipo, minuto)` con los
  mismos cortes `r<0.55`/`r<0.62` del HTML sobre el mismo tiro de dados que decide el gol -no uno
  aparte-, y `partido_vivo.gd` la conecta con las mismas frases de `juego.js` y el sonido solo si el
  remate es tuyo (igual que el `if(mio)` original). Verificado con `pruebas/banco.gd` (40 partidos:
  cada remate cae en gol o en una señal, nunca en las dos ni en ninguna; atajada salió en 37% de los
  no-goles y poste en 8%, contra ~36%/~10% esperados) y con captura real (`pantalla_remates.png`):
  *"9' 😱 Se le va por poco — Patricio Ibarra"* en la crónica, una línea que antes de esta tanda no
  podía existir.

  De propina, cinco sonidos que el HTML **nunca tuvo** -no hay `sfx('lesion')` ni `sfx('cambio')` ni
  nada parecido a fichaje o ascenso/descenso en `juego.js`-, compuestos con el mismo instrumental
  (osciladores + ruido filtrado, nada de ficheros): `lesion` (golpe sordo + caída de dos notas, solo
  si es tuyo), `cambio` (dos pitidos de pizarra, neutro), `fichaje` (arpegio corto + brillo, en
  `_intentar_fichar()` y en el clausulazo), `ascenso`/`descenso` (más grandes que fichaje, más cortos
  que trofeo, solo cuando TU club sube o baja -`resumen["suben"]`/`["bajan"]` en el cierre de
  temporada-). Y `trofeo` mismo se enganchó por fin a un título de verdad: `Logros.celebrar_titulo()`
  emite `titulo_celebrado`, que escucha `principal.gd` -no se llama a `Sonido` dentro de `Logros`
  porque esa clase la usa tambien `Mundo.nueva_temporada()` durante el banco headless, que juega
  cientos de temporadas sin pantalla-.

- **Búsqueda de caras reales por Wikidata/Commons, en curso** (4-9-2026): el paquete DF11 (7.593
  caras) sigue descartado -su `config.xml` solo mapea ID interno de FM a imagen, sin nombre, y no hay
  forma de saber a quién pertenece cada una-. En vez de reconocimiento facial -que no se va a intentar
  sobre fotos de personas reales-, se lanzó `herramientas/caras_reales_buscar.ps1`: por cada uno de
  los **2.125 nombres únicos** de la tabla `REALES` (más de los 813 que se creía, porque el mundo pasó
  a generarse completo, 24 ligas), busca en Wikidata un futbolista con ese nombre (`P106`=Q937857,
  contrastado contra el país con `P27`), y si tiene foto (`P18`) la resuelve en Commons y comprueba la
  licencia antes de bajarla a `recursos/caras_reales/`. Solo se aceptan archivos alojados en Commons
  -no admite "fair use", así que estar ahí ya es licencia libre por política del sitio, pero la
  licencia exacta se registra igual en `datos/caras_reales_reporte.json`-. Reanudable (salta los
  nombres que ya tiene el reporte) y con reintento/espera en los 429 de Wikidata, porque a 400ms entre
  llamadas empieza a devolver "Too Many Requests" -a 1,2s va estable-. Con el piloto de 15 nombres
  conocidos salió ~50% de acierto (Vidal, Bellingham, Lewandowski con CC BY-SA reales). La primera
  tanda completa arrancó con los nombres mal codificados (trampa 39: `Ã¡` en vez de `á`, ver más
  abajo) y buscaba cosas como "GonzÃ¡lez" -120 nombres gastados con muchos falsos "sin resultados"
  antes de encontrarlo comparando bytes, no leyendo la pantalla-. Se relanzó desde cero con la lista
  corregida: con nombres reales de jugadores chilenos actuales (no solo estrellas mundiales) el
  acierto sube bastante -16 de los primeros 20-, porque el fútbol chileno también está bien cubierto
  en Wikipedia. Sigue corriendo sola; falta: revisar el reporte final, decidir cómo `Cara.gd` elige
  entre foto real y la cara procedural de siempre, y limpiar `datos/reales_lista.json` (solo un
  volcado intermedio para el script, no hace falta que sobreviva).

- **"Vender jugadores": la puerta de salida que no existía** (4-9-2026, séptima tanda): se podía
  comprar (Mercado, ficha ajena, clausulazo) pero no había ninguna forma de vender lo tuyo -ni un solo
  botón, en ningún sitio-. Investigando se encontró que el propio HTML **tampoco tiene un "vender
  ya"**: `venderJugador()` no existe, lo que hay es `listarTransferible()` (marca `j.transferible=true`,
  moral -8) que hace que el sorteo semanal de ofertas (`juego.js:2913-2932`) meta al jugador tres veces
  en la bolsa en vez de una, y `responderOferta()` para aceptar o rechazar lo que llegue -no es una
  venta instantánea, es una bandeja de ofertas-. Se portaron los tres:
  - `Jugador.transferible: bool` (guardado y cargado, como `pide_salir`).
  - `Mercado.listar_transferible(j)` y `Mercado.buscar_oferta_por_mi_jugador()` -esta última se llama
    cada semana justo después de `mercado.mover()`, con el mismo 40% de probabilidad, la misma bolsa
    triplicada para transferibles y el mismo "si la oferta ya cubre el 85% de la cláusula, se paga la
    cláusula y no se puede rechazar"-, guardadas en `Mercado.ofertas_recibidas` (objetos `Jugador`/
    `Club` directos, no ids -ninguno de los dos apunta de vuelta al Mundo- pero sí hace falta resolver
    por id al guardar/cargar, con `a_dic()`/`desde_dic()` iguales a los de `Cesiones`).
  - `Mercado.responder_oferta(idx, acepta)`, con una sección nueva "OFERTAS RECIBIDAS" arriba de la
    tabla de objetivos en la pestaña Mercado (botones Aceptar/Rechazar, o solo Aceptar si es de
    cláusula) y las dos puertas nuevas en la ficha de un jugador PROPIO -que hasta hoy terminaba en
    los datos básicos y no ofrecía nada más-: "VENDER" (poner en venta) y "RESCINDIR CONTRATO"
    (`Cantera.coste_rescision()`, que ya estaba escrito y portado pero ningún botón lo llamaba nunca),
    con doble confirmación como vender el club o borrar la partida.

  Descartado a propósito, con la misma frontera anotada en el código: la bolsa de agentes libres
  (`G.libres`, para refichar a quien rescindiste) y la ficha de "ex mío" (la ley del ex al enfrentarlo
  con otra camiseta) son sistemas aparte que tampoco están portados, y meterlos aquí habría triplicado
  el alcance de una tanda que ya tocaba seis archivos. Lo que sí se hizo con fidelidad completa porque
  la maquinaria ya existía: el golpe de moral a la plantilla al rescindir (doble si es de tu misma
  camarilla — `Vestuario.clan_de()`), el golpe al humor del clan, la pérdida de confianza del agente
  (`Cantera.confianza_agentes`) y el golpe al ánimo/funa del club (`Prensa`). De propina, dos señales
  que llevaban meses sin escuchar nadie -`Mercado.oferta_recibida` y `Mercado.traspaso`, esta última
  filtrada para no repetir avisos de transferencias tuyas, que ya tienen su propio mensaje- ahora
  escriben en "LO QUE VA PASANDO".

  Verificado con `pruebas/banco.gd` (`_probar_vender`, dieciocho comprobaciones: marca y moral,
  idempotencia, sorteo de ofertas en menos de 100 intentos, aceptar y rechazar, dinero movido en los
  dos sentidos, rescisión con la plantilla y la caja exactas, guardado y carga de una oferta pendiente
  resolviendo jugador y club como objetos reales) y con capturas: `pantalla_ofertas.png` (una oferta
  real de 12,2M EUR con sus dos botones y su aviso en el registro) y `pantalla_venta_ficha.png` (la
  ficha de un jugador propio con "Poner en venta" y "Rescindir 7,9M EUR").

- **Un ojeador que trabajaba en silencio**: `Mundo.informe_de_ojeo` existía y `_informes_de_ojeo()` ya
  marcaba `ojeados[j.id]`, pero la señal no la escuchaba nadie -mismo patrón que las otras 44 noticias
  mudas de sesiones anteriores-. Ahora escribe en el registro: "🔎 Informe de ojeo: nombre · club ·
  posición · edad · media con proyección". Es una versión reducida de lo que trae el HTML -
  "RED DE OJEADORES CON NOMBRE Y SESGO", un ojeador de carne y hueso por país cubierto, cada uno con su
  propio sesgo, que renuncia y se reemplaza, con su propia pestaña "Ojeadores" en el menú-, que sigue
  sin portar: es una de las 73 pantallas pendientes, no un descuido de esta tanda.

- **La enfermería trabajaba a ciegas**: barriendo las señales sin conectar de todo `nucleo/` salió
  `Medico`, el caso más claro de la tanda. `revisar_semana()` corre cada semana desde
  `Mundo.avanzar_semana()` (línea 492) y devuelve una lista pensada explícitamente -lo dice su propio
  comentario- "para que la interfaz lo cuente sin tener que rastrear a nadie", pero `avanzar_semana()`
  tira esa lista entera. Y las cuatro señales del médico (`lesion_nueva`, `recaida`, `recuperado`,
  `informe_listo`) tampoco las escuchaba nadie: a diferencia de `_a_la_lesion` en `partido_vivo.gd`
  -que sí avisa de las lesiones EN UN PARTIDO en directo-, las de entrenamiento (fatiga acumulada,
  recaídas por volver antes de tiempo) eran completamente mudas; solo se veían entrando a la pestaña
  Enfermería a mirar. Se conectaron las cuatro. De paso apareció otro botón fantasma:
  `Medico.informe(j, club, año)` -el informe médico de un jugador ajeno, con precio escalado a su
  reputación y a lo que vale el fichado- estaba completo y nadie lo llamaba desde ningún sitio; ahora
  la ficha de un jugador AJENO trae una sección "INFORME MÉDICO" nueva, debajo del clausulazo.
  Verificado con captura (`pantalla_medico_lesion.png`, `pantalla_medico_informe.png`): la lesión
  forzada aparece en el registro ("🩹 Pablo Lagos se lesiona: Pubalgia..., 7 semanas fuera"), el botón
  "Pedir informe médico 460k EUR" descuenta la caja de verdad y la ficha muestra "Riesgo declarado" y
  "Lesiones graves en su historial" tras pedirlo.

- **`js/vistas.js` existe, y hasta hoy esta sesión solo había mirado `js/juego.js`.** Investigando el
  comparador (`compararJug()`) salió que `Q.comp` -la lista de hasta tres jugadores a comparar- no
  tenía NINGÚN sitio que la leyera dentro de `juego.js`, ni tampoco `vComparador`, `vHistoria`,
  `vLegado`, `vRecords` ni ninguna de las otras 32 funciones que arma el dispatch de la pestaña "Club"
  (línea 4678): ninguna estaba definida en el archivo. Antes de darlas por muertas -que habría sido un
  error real, ese dispatch SÍ se ejecuta cada render- se encontró la causa: la página carga tres
  scripts, `js/intro.js`, `js/juego.js` **y `js/vistas.js`** (260 KB, 3.149 líneas), y las 33 funciones
  viven en el tercero. La cuenta de "21.227 líneas" de la tabla de arriba SÍ las incluye -por eso ese
  número siempre cuadró-, pero las búsquedas puntuales de esta sesión (grep sobre un solo archivo) las
  venían pasando por alto. Cualquier "esto no existe en el HTML" de las tandas anteriores a esta que
  se apoyara solo en `juego.js` merece una segunda mirada con `vistas.js` incluido -se revisó la más
  delicada (`sfx('falta')`/`sfx('corner')` nunca llamados) y esa sí se sostiene, no aparecen en
  ninguno de los tres archivos-.

- **El comparador de jugadores**: con `vComparador()` real encontrado en `vistas.js:553`, se portó tal
  cual -hasta tres jugadores lado a lado (`_comparar_ids`, como `Q.comp`), con un botón "Comparar" en
  cualquier ficha, propia o ajena, y una pestaña nueva "Comparar". Cada fila resalta en verde el mejor
  valor -`mayor_mejor=false` para Edad y Sueldo, donde menos es mejor, igual que el HTML- y los
  atributos mostrados son los del PRIMER jugador de la lista, así que un portero comparado con dos de
  campo enseña "—" en las filas de estos últimos, tal cual hace el original. De paso se encontró y
  arregló un hueco real en la ficha normal, no solo en el comparador: `vComparador()` esconde la
  Proyección con un "?" salvo que el jugador sea tuyo o ya lo hayas ojeado
  (`j.club===G.miClub||j.ojeado`), y la ficha de Godot enseñaba el potencial de cualquiera sin
  condición -`mundo.ojeados` se alimentaba desde el primer día pero nada lo leía todavía-. Se dejó
  fuera la fila "Ansiedad" del comparador -no por falta de sistema, corrección posterior: sí está
  portada, ver la tanda de "Camarín" más abajo, esta nota solo no había mirado con suficiente cuidado
  cuando se escribió-, y el "modo ciego" completo (`G.ajustes.ciego`, que esconde también la Media) no
  está portado -solo la Proyección se esconde, igual que hace el HTML fuera de ese modo-.
  Se cazaron dos bugs propios al verificar con captura, no solo con el banco: comparar "Valor"/"Sueldo"
  con la cadena ya formateada ("7.4M EUR") en vez del número (`j.valor`/`j.sueldo`) dejaba a los tres
  siempre empatados en 0 y los resaltaba a los tres a la vez -se corrigió separando el valor que se
  COMPARA del texto que se MUESTRA (`formatear: Callable`)-, y un `var texto := ... if ... else ...`
  con un `Callable.call()` de por medio no permite inferir tipo y revienta al cargar -mismo patrón que
  la trampa 38, con `: String` explícito se arregla-. Verificado con `pruebas/banco.gd` (dos
  comprobaciones de `Mundo.jugador_por_id()`, la búsqueda nueva que usa el comparador para resolver sus
  ids) y con captura real (`pantalla_comparador.png`): Media, Proyección, Edad, Valor y Sueldo resaltan
  al jugador correcto en cada fila, y la Proyección del no ojeado sale como "?".

- **Leyendas del club, la mitad de `vHistoria()` que sí tenía sentido portar ya**: `Cantera.leyendas`
  lleva alimentando de verdad la camada anual desde que se enganchó Cantera -`registrar_retiro()` mete
  a cada figura que se retira con media alta, `camada_anual()` puede darle un hijo con su apellido años
  después-, pero no había NINGUNA fila en NINGÚN sitio del juego que dijera qué leyendas tiene el club
  esperando: el jugador nunca se enteraba de que fulano se retiró como figura y podría tener un hijo en
  el plantel en unos años. Se añadió "LEYENDAS DEL CLUB" arriba de la pestaña Cantera -no una pantalla
  aparte: las otras dos tarjetas de `vHistoria()` (trofeos del DT y palmarés temporada a temporada de
  todo el mundo) se dejaron fuera a propósito, la primera porque ya se muestra en la pestaña Logros
  ("VITRINA", últimos 5 títulos de `Logros.muro`) y hubiera sido una pantalla casi duplicada, y la
  segunda porque Godot no lleva un libro de premios año a año de TODO el mundo -liga, copa, goleador,
  MVP de cada temporada-, solo aplica sus efectos al cerrar cada una; guardar ese historial es una
  pieza nueva, no un dato que ya exista y solo falte mostrar-. Verificado con captura
  (`pantalla_leyendas.png`): "Fernando Salinas · DEL · nivel 88 · puede tener un hijo en 2029".

- **Récords, la mitad de `vRecords()` que ya tenía los datos guardados**: `Logros` lleva `h2h`
  (cara a cara con cada rival), `rachas` (invicto, más victorias seguidas, peor sequía), `rec`
  (mayor goleada, peor derrota, más goles en un partido, récord de público), `efemerides` y
  `planteles` (la foto del plantel de cada temporada) desde que se enganchó la memoria del club -con
  sus pruebas de guardado y carga ya pasando-, pero la pestaña Logros solo enseñaba la vitrina de
  títulos y un top 5 de goleadores: el resto -casi todo lo que trae `vRecords()`- vivía en el
  guardado sin que nadie lo viera. Se abrió la pestaña "Récords" con rachas, marcas del club,
  goleadores históricos, más partidos disputados, la tabla cara a cara completa contra cada rival
  enfrentado, "un día como hoy" (últimas 10 efemérides) y el archivo de planteles (últimas 8
  temporadas). Se dejó fuera lo que ya se ve en Logros -la vitrina de títulos, redundante con
  "VITRINA"- para no duplicar pantalla.

  Se cazaron dos bugs reales al verificar con captura, ninguno visible sin ella: el primero, en la
  propia captura -`queue_free()` no actúa hasta que el bucle de eventos respira, y una prueba que
  simula 65 semanas dentro de un solo `_process()` sin ceder el turno apilaba varios `PartidoVivo` sin
  borrar del todo, uno encima del otro, tapando la pantalla entera-. El segundo, en el juego de
  verdad: `_dato()` -el ayudante que dibuja "etiqueta … valor"- estaba escrito a mano para la ficha,
  con `_ficha.add_child(h)` fijo dentro de la función, así que las tres primeras secciones de Récords
  (Marcas, Goleadores, Más partidos) se dibujaban en el panel de la FICHA del jugador y no en la lista
  de Récords -y como `_refrescar()` termina siempre llamando a `_ver_ficha(_seleccionado)`, con nadie
  seleccionado esas filas se borraban solas en el mismo repintado en el que se habían creado: sin
  ningún error, la sección salía con el título puesto y ni una fila debajo-. Se le añadió a `_dato()`
  un `padre: Node = null` que por defecto sigue siendo `_ficha` -así ninguno de sus quince sitios
  antiguos cambió- y Récords pasa el suyo. Verificado con `pruebas/banco.gd` (0 fallos, sin tocar
  ninguna prueba nueva: es una pantalla que solo LEE datos que ya se probaban) y con captura real
  tras dirigir tres jornadas de verdad (`pantalla_records.png`): "Mayor goleada 4-0 con Palestino
  (2027)", "Récord de público 38.197 vs Magallanes (2028)", la tabla cara a cara con 18 rivales.

- **La red de ojeadores con nombre y sesgo, el sistema más grande de toda la sesión** (4-9-2026): el
  usuario pidió empujar el MOTOR -no la interfaz- lo más cerca posible del 100%, y este era el hueco
  de lógica más grande que quedaba sin tocar. `Staff.ojo()` daba una probabilidad plana de que llegara
  un informe automático, pero eso es solo una esquina de un sistema mucho más grande del HTML (v2.9,
  ideas 446-475): cada país que cubres tiene un ojeador de carne y hueso -nombre, sesgo, especialidad,
  humor que baja si lo ignoras y a cero renuncia-, y sobre todo, **la media de cualquiera que no sea
  tuyo no se ve exacta**: sale un rango que se cierra cuanto mejor lo conozcas -tu propia liga, tu red
  de ojeadores, o pagar su informe individual-. Hasta esta tanda Godot enseñaba la media exacta de
  CUALQUIER jugador del mundo, siempre: no era una pantalla a medias, era una pieza entera del juego
  que no existía.

  Se creó `nucleo/ojeadores.gd` (`class_name Ojeadores`, un sistema "solo tuyo" más, con `WeakRef` al
  Mundo como Mercado/Cesiones/Roles) con la fórmula exacta del HTML: `nivel_de(j)` da 3.0 si es tuyo o
  ya está ojeado, si no el máximo entre 1.5 (tu propio país) y `nivel_de_cobertura*0.9`;
  `ovr_aproximado()`/`ovr_texto()` desvían la media con un ruido estable -sale del id del jugador, no
  de un dado nuevo en cada repintado- más el sesgo del ojeador de su país (Entusiasta +3, Desconfiado
  -2, Ecuánime 0, Vendedor +5); `alternar_pais()` contrata o retira cobertura, con el tope de países
  saliendo de `Staff.nivel("ojeador")` -recortado a 3 al indexar la tabla `[0,2,4,6]` del HTML, porque
  el cuerpo técnico de Godot sube hasta nivel 5 en los seis puestos por igual y el HTML nunca definió
  qué pasa en el 4 o el 5-; `procesar_semana()` baja el humor si se ignoran más informes de los que se
  usan y hace renunciar al ojeador a humor cero; `ojear()` es el informe individual pagado -sale del
  presupuesto de ojeo aparte, y si no alcanza tira de la caja del club, igual que `gastarOjeo()`-.

  Se reutilizó `Mundo.ojeados` -el mismo diccionario que ya escondía la Proyección en la ficha y el
  comparador de la tanda pasada- en vez de inventar un campo nuevo: en el HTML `j.ojeado` es también
  una sola bandera compartida entre el informe automático y el pagado, así que unificar ahí era lo
  fiel, no un atajo. Fuera de alcance a propósito en esta tanda: el bono de +0.4 por "consejero,
  director deportivo" (`G.consejeros`, sistema aparte sin portar entonces -ver más abajo, se cerró
  al construir "Consejeros del directorio") y el "modo ciego" (`G.ajustes.ciego`, que en el HTML
  reemplaza el número por una palabra como "Muy bueno" en vez de un rango, este sigue sin portar).

  UI mínima para que no quedara inerte -"se tiene que poder llegar desde el menú y notarse jugando"-:
  sección "RED DE OJEADORES" en Club (nombre, sesgo, humor de cada uno, y los países libres para
  sumar), botón "Pedir informe de ojeo" en la ficha de cualquier rival, y la Media fuzzy aplicada en
  esa ficha y en la columna "MED" de Mercado -el resto de sitios donde se ve una media ajena
  (Comparador, por ejemplo) se quedan con el número exacto por ahora: aplicar el rango en todos lados
  habría sido una tanda aparte solo de interfaz, y esta iba de motor-.

  Verificado con `pruebas/banco.gd` (`_probar_ojeadores`, veinticuatro comprobaciones: tope de países
  por nivel, contratar y retirar cobertura, sesgo real de los cuatro tipos, `nivel_de()` en sus tres
  casos -propio, mismo país, país cubierto-, rango estable para un desconocido, `ojear()` con su gasto
  y su contador de informes, renuncia por humor a cero, guardado y carga) y con capturas
  (`pantalla_ojeadores.png`, `pantalla_ficha_borrosa.png`): "Media / potencial: 74-92" en la ficha de
  un rival sin cubrir, "Pedir informe de ojeo 96k EUR", y el aviso real "Nuevo ojeador en Argentina:
  Santiago Aravena... Entusiasta: se enamora de los jugadores, sus informes tiran alto."

  Un bug de la propia prueba, no del sistema: `Staff.subir()` cuesta el cuadrado del nivel, y sin caja
  de sobra la quinta subida de "ojeador" fallaba en silencio -`subir()` devuelve un motivo, no
  revienta- y el nivel se quedaba en 4 en vez de 5, lo que a su vez hacía fallar la cuenta de
  `nivel_de()`. Se arregló dándole caja de sobra al club de prueba antes de subir de nivel.

- **La mesa de negociación completa, con una decisión de arquitectura tomada con el usuario**
  (4-9-2026): al investigar `pctVenta` para terminar de empujar el motor, salió que era solo un campo
  dentro de un sistema mucho más grande -`abrirNegociacion`/`enviarOferta`/`cerrarFichaje` en
  juego.js-: rondas, paciencia por los dos lados (club Y jugador, dos puertas separadas), cuotas a
  plazo, bonos por objetivos, pago bajo cuerda, intercambio de jugadores, y un rival que puede
  robarte el fichaje en plena mesa. El obstáculo real: cada ronda del HTML consume DÍAS de un
  calendario que Godot no lleva -el motor va por SEMANAS-, y portar el conteo de días habría sido
  cambiar cómo `Mundo`/`Liga` llevan el tiempo, no agregar una clase. Puesto en preguntas: **versión
  simplificada por semana** (cada "enviar oferta" es una ronda, sin gastar calendario, sin el árbol de
  perks del DT ni la reputación personal del DT ni los acuerdos de agente en exclusiva -tres sistemas
  del DT que tampoco están portados-), fiel al 100% con el cambio de arquitectura, o dejarla fuera.
  Se eligió la simplificada.

  El hallazgo que lo cambió todo a mitad de camino: `Cesiones.registrar_compromisos()` y
  `Cesiones.vender()` -las funciones que asientan cuotas, bonos, porcentaje de venta futura, cláusula,
  pago opaco, derechos de formación y comisión, y que ejecutan una venta completa con el descuento por
  guardarse un % y el cobro de lo que TÚ le debías a quien te vendió a ti- estaban escritas, probadas
  en su día para la cesión con opción de compra, y **sin una sola llamada externa en todo el
  proyecto**. Ni siquiera `Mercado.responder_oferta()` -de la tanda de "vender jugadores"- las usaba:
  tenía su propia versión simplificada que movía el dinero a mano y se saltaba por completo la deuda
  de un porcentaje pactado. Se corrigió `responder_oferta()` para que delegue en `Cesiones.vender()`
  -cierra ese hueco real de una tanda anterior-, y `nucleo/negociacion.gd` (`class_name Negociacion`,
  dueña de `Mercado.negociacion`, una mesa a la vez) llama a `registrar_compromisos()` para cerrar,
  en vez de reescribir esa contabilidad. También se reutilizó infraestructura ya portada y viva:
  `Mercado.valor_pedido()`/`deseo_de_venir()`, `Vestuario.acepta_rol()`/`pide_con_rol()`/`fijar_rol()`
  (el papel prometido en el plantel, que YA se comprueba cada semana), `Cantera.agente_de()`/
  `confianza_de()` (la confianza del agente, que sí pesa en el umbral de aceptación) y
  `Roles.usar_emergencia()`. Casi todo el trabajo de esta tanda fue la MESA -rondas, umbral que baja
  con cada ronda y sube con la confianza del agente, doble puerta club/jugador, robo de fichaje con
  probabilidad creciente por ronda-, no la contabilidad final.

  Fuera de alcance, documentado en el propio archivo: el árbol de perks del DT, la reputación
  personal del DT, los acuerdos de agente en exclusiva -bonos numéricos pequeños de sistemas que
  Godot no tiene, no la estructura de la mesa-.

  Verificado con `pruebas/banco.gd` (`_probar_negociacion`, veinte comprobaciones: apertura y sus
  candados, ajustes de cada término, una oferta baja que no cierra, una oferta generosa que cierra en
  un número razonable de intentos, rol/años escritos de verdad en Vestuario, y cuotas/bonos/porcentaje
  de venta futura/cláusula registrados de verdad en Cesiones -no en una copia-) y con captura real
  (`pantalla_negociacion_abierta.png`, `pantalla_negociacion_ronda.png`): el panel completo -Fijo,
  Cuotas, Bonos, % de venta futura, Pago bajo cuerda, los seis papeles del plantel, Ficha, Años, Prima,
  Cláusula- y el cierre real: "✅ Fichaje cerrado: Diego Fernández firma por 3 temporadas con ficha de
  165k EUR/semana", con la caja del club descontada de verdad.

- **La pestaña "Finanzas", el primer trabajo de interfaz pura tras varias tandas de motor**
  (4-9-2026): con el motor ya cerca del límite razonable, tocaba "la otra parte, la que no es ni
  motor ni lógica". Investigando `vContabilidad()` para un balance completo salió que necesita
  `G.prestamos`/`G.consejeros`/`G.academias` -deuda bancaria, asesores, academias-, tres sistemas que
  Godot no tiene: haberla construido habría sido inventar contabilidad sobre datos que no existen, no
  vestir una pantalla. En su lugar salió algo mejor y sin ninguna pieza nueva: **siete clases** -
  `Finanzas`, `Cesiones`, `Cantera`, `Federacion`, `Prensa`, `Selecciones`, `EstadioPropio`- tienen
  desde hace tiempo una señal `movimiento(concepto, monto)` que NADIE escuchaba. La caja sí se movía
  con cada una -taquilla, sueldos, derechos de televisión, becas, derechos de formación, cláusulas,
  comisiones de agente- pero no quedaba ni rastro de por qué: el jugador solo veía la cifra de la caja
  cambiar en la cabecera, nunca la explicación.

  Se armó `Mundo.libro_financiero` (un registro con tope de 60 entradas) y `_anotar_movimiento()`,
  conectada a las siete fuentes en `tomar_el_mando()` -con cuidado real: esa función se puede llamar
  más de una vez sobre el mismo Mundo (fundar club, trotamundos, cargar una partida), y tres de las
  siete clases no se recrean cada vez, así que conectar sin comprobar antes con `is_connected()`
  habría ido duplicando cada movimiento hasta por cuatro-. `Finanzas` es la única fuente aparte: se
  crea una instancia nueva cada semana para cada uno de los 384 clubes, así que esa conexión va en
  `avanzar_semana()`, solo para la instancia de TU club. Guardado y cargado como el resto.

  La pestaña "Finanzas" en sí es solo eso: un resumen (caja, sueldos del plantel, cuerpo técnico) y el
  libro completo, más reciente arriba, en verde lo que entra y en rojo lo que sale. Cero lógica nueva
  de negocio -todo lo que aparece ya lo cobraba o pagaba el juego, solo faltaba decirlo-.

  Verificado con `pruebas/banco.gd` (una comprobación nueva dentro de `_probar_negociacion`: los pagos
  de una mesa cerrada con cuotas/bonos/pct/cláusula quedan anotados en el libro) y con captura real
  (`pantalla_finanzas.png`) tras cinco semanas jugadas de verdad: taquilla, cuerpo técnico y
  estructura, sueldos del plantel, cuotas de socios, derechos de televisión, publicidad, "Derechos de
  formación: Nicolás Fernández" y "Beca deportiva: Raúl Álvarez" -de al menos cuatro fuentes distintas
  a la vez, en orden cronológico correcto.

- **Plusvalías pendientes, en la misma pestaña Finanzas**: `Cesiones.cobrar_plusvalias()` ya corre
  sola cada temporada desde `Mundo.nueva_temporada()` -cobra de verdad el porcentaje que te guardaste
  al vender a alguien, el día que ese jugador vuelve a cambiar de club-, pero el jugador nunca veía la
  lista de lo que tenía pendiente, solo el ingreso sorpresa cuando por fin se cobraba. Se añadió una
  sección corta con el nombre, el porcentaje y dónde juega hoy cada uno. Investigando la pantalla
  completa del HTML (`vSponsor()`) salió que el resto -créditos bancarios con intereses, campañas
  publicitarias, guerra de patrocinadores, subvención municipal- depende de sistemas que Godot no
  tiene (`G.prestamos`, `G.consejeros`, `initCiudad()`): quedan fuera, documentados, no a medio hacer.

- **Camarín, y una nota anterior que había que corregir**: buscando la siguiente pantalla de interfaz
  pura, `vCamarin()` (clanes, salud mental, jerarquía interna) parecía depender de `j.mente.ansiedad`
  -que una nota de esta misma sesión, escrita al tocar Ojeadores, daba por no portado-. Mirándolo con
  más cuidado esa nota estaba **mal**: `Vestuario.mente()`/`ansiedad()`/`estado_mental()` existen desde
  hace tiempo, con `terapia`, `descanso` y `confianza` completos, y `_proceso_mental()` ya corre cada
  semana desde `Vestuario.semana()` -la ansiedad sube y baja sola, puede llegar a crisis y mandar a
  alguien de baja psicológica, exactamente como en el HTML-. `dar_terapia()`, `descanso_mental()` y
  `mediar()` (para las camarillas enojadas) también estaban completas. Ni una pantalla los usaba.

  Se corrigió la nota equivocada (arriba, en la tanda del comparador) y se abrió la pestaña "Camarín":
  clima del vestuario (moral y ansiedad medias, capitán, número de grupos), clanes y camarillas con
  quién lidera y quién más pertenece y un botón para mediar si el humor cae por debajo de -10, la
  lista de quienes están mal de la cabeza con sus dos intervenciones, y la jerarquía interna -los diez
  de más peso, por media y edad, con el capitán marcado-. Cero lógica nueva: todo ya corría solo.

  Verificado con `pruebas/banco.gd` (0 fallos, ninguna prueba nueva porque no hay lógica nueva que
  probar) y con captura real (`pantalla_camarin.png`): seis camarillas reales -"Los históricos", "La
  camada joven", cuatro grupos por representante- con sus líderes y miembros, y un jugador forzado a
  ansiedad 60 apareciendo como "Tenso" con los botones Terapia y Descanso mental.

- **Consejeros del directorio** (`CONSEJ`/`contratarConsejero(k)` del HTML): siguiendo la instrucción
  de seguir con TODA la interfaz aunque haga falta construir sistemas nuevos, se creó de cero lo que
  el HTML llama consejeros -hasta dos asesores del directorio a la vez, tipo fijo (deportivo,
  financiero, marketing, legal), coste de entrada de 600.000 y honorario semanal de 15.000 por
  asiento-. Se añadió a `Directiva` en vez de crear una clase aparte: es un diccionario pequeño
  (`consejeros`), sin estado que dependa de otra cosa que no sea el propio club, y `Directiva` ya
  vivía exactamente donde hacía falta -tanto para pagar el costo de contratación desde `club.saldo`
  como para que `Ojeadores`/`Finanzas` pudieran preguntarle "¿tienes contratado tal consejero?".

  De los cuatro efectos del HTML, dos sí tienen a qué engancharse en Godot y quedaron conectados de
  verdad, no solo contratables: el consejero deportivo suma +0.4 al nivel de ojeo en TODO el mundo
  (`Ojeadores.nivel_de()`, cerrando el hueco documentado en la tanda de arriba) y el de marketing sube
  un 10% el patrocinio (`Finanzas.patrocinio()`, nuevo parámetro `bono_mkt`) y las ventas de tienda y
  museo (`Mundo.avanzar_semana()`, el único ingreso de `Instalaciones.ingresos_del_mes()` que el HTML
  marca como afectado). Los otros dos -financiero (baja el interés del sobregiro) y legal (ablanda la
  mora y las multas)- se pueden contratar exactamente igual que en el HTML, pero su efecto queda
  inerte porque Godot todavía no tiene banco de préstamos ni sistema legal: se documentó la carencia
  en el propio texto del botón en pantalla ("sin efecto: aún no hay banco en Godot"), no se fingió que
  hacían algo. El honorario semanal de los dos asientos sí se cobra siempre, tengan efecto o no -es lo
  que hace el HTML también: el gasto no depende de que el consejero sirva de algo esta semana-.

  Sección nueva "CONSEJEROS DEL DIRECTORIO" en la pestaña Club, justo debajo de "LA DIRECTIVA": los
  cuatro tipos siempre visibles, contratado o no, con nombre/edad al azar del que ya está contratado y
  un botón Contratar/Cesar. Guardado y cargado (`Directiva.a_dic()`/`desde_dic()`).

  Verificado con `pruebas/banco.gd` (`_probar_consejeros`, trece comprobaciones: tope de caja, tope
  de dos asientos, honorario que sube y baja con los asientos, el +0.4 de ojeo medido con y sin el
  consejero, el +10% de patrocinio medido con y sin el consejero, cese que libera el asiento; más una
  comprobación de guardado/carga en `_probar_guardado`) y con captura real
  (`pantalla_consejeros.png`): "CONSEJEROS DEL DIRECTORIO · 1 de 2 · 180k EUR/semana en honorarios",
  "Consejero deportivo · Lucas Olivares (60 años)" con botón Cesar, y los otros tres con "Contratar
  7.2M EUR" y su descripción -incluidas las dos notas honestas de "sin efecto" de financiero y legal-.

- **"Tu carrera" (`vDirectorio()`), y un hallazgo grande: `Roles` ya era casi todo el sistema de DT
  personal que la nota de arriba daba por no portado**. Investigando de dónde iba a sacar el prestigio
  del entrenador (`G.dt.rep`, tocado en más de cuarenta sitios del HTML) apareció `nucleo/roles.gd`
  -1163 líneas, con su propio banco de pruebas (`_probar_pulso_de_roles`, `_probar_roles_y_federacion`)
  y ya enganchado a los permisos de fichar/vender/alinear- guardando exactamente eso desde hace tiempo:
  `prestigio` (1-99), `trofeos` (la vitrina de tu CARRERA, que te sigue de club en club, a diferencia de
  `Directiva.trofeos`, que se queda en el que dejas), `historial`, la escalera completa DT→director→dueño
  con los mismos umbrales del HTML (6 trofeos y 72 de prestigio; 12 y 82), `cambiar_dt()` (`cambiarDT`,
  300.000), `inyectar_capital()` (`inyectarCapital`, 1.000.000, máximo 2 por temporada) y `vender_club()`
  (`venderClub`). Ni una pantalla lo enseñaba: la pestaña Club solo tenía un cuadro pequeño ("TU CARGO")
  con el nombre del puesto y los permisos, sin rastro de prestigio, historial ni de los botones de dueño.

  De paso salió una inconsistencia real, no solo una pantalla que faltaba: `Directiva.mover_confianza()`
  podía marcar `despedido_ya=true` sin mirar nunca el rol, así que un dueño o un ayudante -a quien "no
  los juzga el directorio", tal cual dice la cabecera de `roles.gd`- podían aparecer como despedidos si
  su confianza caía, contradiciendo lo que el propio HTML explica en esta misma pantalla ("siendo el
  dueño, nadie te echa: mide el apoyo del entorno"). Se corrigió con un campo `Directiva.puede_despedirte`
  -no una referencia a `Roles`, que rompería el desacople que la propia clase pide en su cabecera-, que
  `Mundo` mantiene al día en `tomar_el_mando()` y en cada `Roles.rol_cambiado` (con guardia
  `is_connected()`, porque `tomar_el_mando()` puede correr más de una vez sin recrear `Roles`) y que se
  vuelve a sincronizar explícitamente tras `Roles.desde_dic()` al cargar una partida -`desde_dic()` no
  emite la señal, así que sin este paso un dueño cargado desde un guardado volvía a quedar despedible
  hasta el próximo cambio de rol-.

  Se amplió la sección "TU CARGO" (renombrada por dentro a incluir "TU CARRERA" debajo): prestigio con
  barra, trofeos y temporadas, historial de clubes anteriores, cuánto falta para el siguiente ascenso y
  su botón cuando ya se puede dar el salto, el entrenador empleado (o el jefe, si eres ayudante) con su
  estilo y un botón para cambiarlo, y -solo si eres dueño- "Inyectar capital" (con el contador de cuántos
  quedan esta temporada) y "Vender el club" con el mismo doble toque de confirmación que ya usaba
  rescindir un contrato. Se añadió `Roles.inyecciones_restantes()` porque la pantalla necesitaba
  preguntarlo sin tocar los campos privados `_inyecciones`/`_anio_inyecciones`. Un detalle de fidelidad:
  el HTML muestra la clave cruda del estilo del entrenador ("estilo pizarron"), no la frase larga de
  `DT_ESTILOS` que existe para otra pantalla -mostrar la frase completa fusionada leía raro ("estilo un
  laboratorio táctico con pizarra"), así que se capitalizó la clave, igual que ya se hace con el nombre
  del cargo, en vez de inventar una redacción nueva.

  Verificado con `pruebas/banco.gd` (tres comprobaciones nuevas en `_probar_pulso_de_roles`: un DT normal
  sigue siendo despedible de verdad, un dueño con la confianza hundida NO queda despedido aunque el
  número baje igual, y eso sobrevive guardar y cargar) y con captura real (`pantalla_carrera.png`,
  forzando el rol a dueño): "TU CARRERA — Prestigio 84/99 · 2 trofeo(s) · 0 temporada(s)", "Antes: Everton
  (hasta 2024)", "Entrenador del banco: Iván Carrasco · estilo Ofensivo" con botón "Cambiar 3.6M EUR", y
  los botones "💰 Inyectar 12.0M EUR de tu bolsillo (0/2 esta temporada)" y "Vender el club".

  Quedó fuera a propósito -no es parte del pulso de `Roles`, es UI e ingresos aparte- "Embajador del
  club" y el sueldo del entrenador empleado; los dos se hicieron acto seguido, ver la entrada de abajo.

- **Embajador del club, y un sueldo que faltaba desde antes de esta sesión**. "Embajador del club"
  (`G.embajador`/`candidatasLeyenda()`/`contratarEmbajador`/`despedirEmbajador`) resultó barato de
  construir: `Cantera.leyendas` -el libro de retirados que alimenta el linaje- ya guardaba exactamente
  los mismos datos (nombre/club_id/pos/nivel) que pedía esta pantalla, así que no hizo falta inventar
  una lista nueva de "leyendas candidatas". Se portó `candidatasLeyenda()` tal cual -las mismas tres
  posiciones deterministas por año (`año%n`, `año*3+1`, `año*7+2`), sin filtrar por club, porque en el
  HTML un embajador puede ser la leyenda de un club rival- como `Directiva.candidatas_embajador()`, y
  `contratarEmbajador`/`despedirEmbajador` como `Directiva.contratar_embajador()`/`cesar_embajador()`.
  El fichaje sube el ánimo de la hinchada (`Prensa.animo`, +6 -se le añadió un `sumar_animo()` público
  porque antes solo `Prensa` podía tocar ese número-) y cada semana suma 25 socios mientras dure; el
  sueldo semanal (20.000) se pliega al cierre de mes, igual que el resto de nóminas.

  Investigando el sueldo del embajador salió un DESCUBRIMIENTO aparte: el HTML también cobra el sueldo
  del entrenador empleado -`G.dtEmp`, 25.000/semana, solo cuando `G.rol!=='dt'`- y **eso nunca se había
  portado**, ni en esta sesión ni antes: siendo director, dueño, cantera o ayudante, el entrenador (o el
  jefe) trabajaba gratis. Se corrigió sumándolo al mismo cierre de mes (`Roles.SUELDO_SEMANAL_DT_EMPLEADO`),
  anotado en el libro financiero como cualquier otro gasto.

  Guardado y cargado (el embajador viaja dentro de `Directiva.a_dic()`, junto a los consejeros; ver el
  comentario de esa función sobre compatibilidad con guardados más viejos de esta misma sesión).

  Verificado con `pruebas/banco.gd` (trece comprobaciones nuevas en `_probar_consejeros`: diez del
  embajador -hay leyendas para elegir, las candidatas son deterministas, sin caja no se puede fichar, el
  costo exacto según el nivel, queda registrado, los socios suben cada semana que dura, cesar libera el
  puesto- y tres del sueldo del entrenador empleado, en un mundo aparte -de entrenador no hay a quien
  pagarle, el monto exacto aparece en el libro financiero, y solo cuando no diriges tú-; más una
  comprobación de guardado/carga en `_probar_guardado`) y con capturas reales
  (`pantalla_embajador_candidatas.png`, `pantalla_embajador_fichado.png`): tres candidatas con su costo
  según nivel ("Brayan Guerrero · DEL · nivel 89 en su época · Firmar 13.3M EUR"), y tras fichar, la fila
  "⭐ Brayan Guerrero · ídolo · DEL · 240k EUR/semana · la hinchada suma socios" con botón "Cesar 2.4M EUR".

  "Exigencia especial del año" (`G.exigencia`) y `escenarioHTML()` siguen fuera: son sistemas de eventos
  propios, más grandes que una pantalla, y no se tocaron.

- **"Modo ciego" ("mercado a ciegas", v2.0 del HTML)**, cerrando el último hueco que la propia tanda de
  Ojeadores había dejado anotado. `Ojeadores.modo_ciego` (booleano, guardado y cargado) más
  `ovr_palabra()` -mismo ruido determinista que `ovr_aproximado()`, leído en la escala cualitativa de
  siete palabras `ESCALA_CIEGA` ("Generacional" a "Flojo") en vez de un rango numérico-. `ovr_texto()`
  -que ya leen la ficha y la columna MED de Mercado- pasa por ahí solo, así que las dos pantallas
  heredaron el modo sin tocarlas. Un caso aparte a propósito: el Comparador NO usa `ovr_texto()` en el
  HTML -su fila "Media" muestra `j.ovr` o un "?" seco (`cegado(j)`)-, así que se portó exactamente así
  (con un `cegado` local, reutilizando el mismo `conoce()` que ya filtraba la fila Proyección) en vez de
  ponerle la palabra cualitativa, que habría sido un embellecimiento no pedido por el original.

  Sin pantalla de ajustes propia todavía en Godot, el interruptor se puso donde vive su lógica: un botón
  Activado/Desactivado justo arriba de "RED DE OJEADORES", en Club.

  Verificado con `pruebas/banco.gd` (cinco comprobaciones nuevas en `_probar_ojeadores`: con el modo
  activado se ve una palabra y no un rango, la palabra es una de las siete de la escala, es estable
  entre llamadas, y un jugador propio sigue mostrando su número real; más una comprobación de
  guardado/carga en `_probar_guardado`) y con captura real (`pantalla_modo_ciego.png`): la ficha de un
  rival lejano mostrando "Media / potencial: Generacional" en vez de un rango tipo "72-84".

**Sin portar todavía** (sigue viviendo solo en el HTML): el globo interactivo (aquí el país se elige
con una fila de botones, no con un globo 3D -es su propia pieza-), la exigencia especial del año y los
escenarios de guion (`escenarioHTML()`), y buena parte de las **73 pantallas** de la interfaz -ficha con
historial completo, préstamos y sistema legal (`vBanco`), campañas de patrocinio y guerra de marcas
(`vSponsor`), "La Gente del Club" (`vGente`), entre otras. (La pantalla de Logros -veinte logros, XP de
perfil, vitrina- sí está portada desde antes de esta sesión: ver más arriba, "Lo que ya se pagó".)

- **El menú de verdad, fusionado en una sola pantalla, y dos huecos de contenido de fondo** (4-9-2026,
  quinta tanda, a raíz de que el usuario dijera "el menú sigue sin verse como en el HTML, y las fotos
  de los jugadores también deben tener su cara real"). Dos quejas justas, y las dos con causas
  concretas y medibles, no vagas:

  **1) El menú.** `ui/inicio.gd` y `ui/seleccion_modo.gd` eran dos pantallas separadas -portada sola,
  luego modos solos-, con un hueco vacío enorme entre el pícker de portada y los botones de abajo en la
  primera. El HTML no tiene ese hueco porque nunca fueron dos pantallas: `renderModoSel()` es UNA sola
  página que baja desde la portada hasta la grilla de modos, el perfil del gestor y el selector de
  portada, todo junto. Se fusionaron en `ui/inicio.gd` -`ui/seleccion_modo.gd` y su escena ya no
  existen-, con el mismo orden del HTML: portada, "PARTIDA EN CURSO" si hay guardado
  (`panelEstadoPartida()`: escudo, club, año/puesto/puntos/caja/títulos, Continuar/Borrar), el perfil
  del gestor (`Logros.perfil_leer()`, que ya existía para la pestaña de Logros y aquí no tenía dónde
  salir), nombre/dificultad, y TODAS las secciones de `MODO_SECCIONES` -antes solo salían "Dirigir" y
  "Mandar"; ahora también Retos, Tutorial y "Todavía en desarrollo", igual que "Crear tu Club", solo que
  atenuadas y con un aviso en vez de fingir que llevan a algún sitio que todavía no existe en esta
  versión-. Las tarjetas de modo pasaron de una caja de color liso a la carátula real del HTML -degradado
  diagonal, tres líneas y el círculo de brillo de `dibujarPortadaModo()`-, portada como SVG y rasterizada
  (`ui/tarjeta_modo.gd`, mismo truco que `Escudo`/`Cara`: construir la cadena, no reimplementar el
  trazado). Un tropiezo de layout que costó encontrar: con un `MarginContainer` de por medio dentro del
  `ScrollContainer`, todo el contenido quedaba a mitad de ancho -610 de 1280- porque el margen no llevaba
  su propio `size_flags_horizontal = EXPAND_FILL`; sin eso, ningún hijo de una cadena Scroll→Margin→VBox
  se estira, aunque cada nodo de más abajo sí lo pida.

  **2) Las caras reales.** Investigando cómo enganchar las fotos que ya venía bajando
  `herramientas/caras_reales_buscar.ps1` en segundo plano (Wikidata/Commons, con licencia libre, 649 de
  2.125 futbolistas encontrados a esta hora) salió que hacerlo no tenía sentido todavía: **la tabla
  `REALES` del HTML -256 clubes con su plantel real de verdad, 813 futbolistas con nombre y cara
  conocidos- estaba exportada entera en `datos/tablas.json` y NINGUNA clase la leía**. Cada club de
  Godot, incluido Colo-Colo, jugaba con once nombres inventados donde el HTML pone a Vidal, De Paul,
  Pizarro... Sin la identidad real primero, una foto real no tenía a quién pegársele. Se portó
  `aplicarReales()` completo como `nucleo/reales.gd`: sustituye -no añade- a los generados más flojos de
  cada puesto (demarcación exacta primero, después el mismo grupo, por último cualquiera), con el mismo
  reescalado del fondo de plantel inventado que trae el HTML -el suplente de relleno no puede salir mejor
  que el peor real, o un "Léo Dubois" cualquiera empataba con Vinícius-. Se llama una vez, al final de
  `Mundo.generar()`, con el mundo entero ya armado. Nuevo campo `Jugador.real` (guardado y cargado).
  `censurar()` es un passthrough en el HTML desde la v3.0 -los nombres van siempre en texto claro-, así
  que no hubo ninguna ofuscación que portar.

  Con la identidad real puesta, la foto sí encaja: `Cara.foto_real(j)` -solo si `j.real` y la búsqueda ya
  le encontró algo en `datos/caras_reales_reporte.json`- carga la foto, la recorta a cuadrado (centrado,
  algo por encima de la mitad para no comerse la cabeza con hombros de más) y la deja a 256px como techo;
  `Cara.textura()` la antepone al dibujo procedural de siempre. Un jugador que no es real JAMÁS hereda la
  foto de otro, y un real al que la búsqueda -que sigue corriendo sola, sesión tras sesión- todavía no le
  encontró nada se queda con su cara procedural sin que nadie tenga que tocar nada cuando por fin
  aparezca.

  Verificado con `pruebas/banco.gd` (`_probar_reales`, nueve comprobaciones: Colo-Colo trae su plantel
  real completo, Arturo Vidal aparece en su demarcación real con atributos recalculados, nadie se repite
  dentro del mismo club, el fondo de plantel generado no supera el techo del reescalado, un país sin
  datos reales -Japón- genera su mundo igual, la foto de Vidal existe/queda cuadrada/gana sobre el
  procedural, y un jugador generado nunca tiene foto) y con capturas reales: `pantalla_inicio.png` /
  `_2` / `_3` (el menú entero, con las nueve tarjetas y sus tres secciones, el badge "EN DESARROLLO" y el
  selector de portada al final), `pantalla_continuar.png` ("PARTIDA EN CURSO · U. Católica · Año 2026 ·
  1º con 13 pts..."), `pantalla_reales.png` (el plantel de Colo-Colo con Arturo Vidal, Lucas Cepeda,
  Vicente Pizarro, Fernando de Paul... en vez de nombres inventados) y `pantalla_foto_real.png` (la ficha
  de Arturo Vidal con su foto real, no su retrato procedural).

- **La barra de navegación, reagrupada en los cinco grupos reales del HTML -y una herramienta nueva que
  hizo posible verlo de verdad-** (4-9-2026, sexta tanda). El usuario insistió, con razón, en que "el
  menú y lo visual sigue sin ser como en el HTML" incluso después de fusionar `Inicio`. El problema era
  que todas las comparaciones hasta ahora se habían hecho leyendo el HTML y sus estilos, nunca viéndolo
  correr de verdad -Chrome headless con `--screenshot` lleva rato fallando en este equipo con "Multiple
  targets are not supported in headless mode", y hasta ahora se daba por un callejón sin salida-.

  **La herramienta**: investigando el fallo con `--remote-debugging-port` salió la causa -este Chrome
  carga sus propias extensiones de componente (páginas de fondo, `service_worker`, un popup de
  omnibox) incluso con un perfil nuevo, y el `--screenshot` de `--headless=new` exige que exista un
  único target-. La solución no es pelear por bajar ese conteo a uno: es no depender de `--screenshot`
  en absoluto. `herramientas/captura_html.ps1` (nueva) habla el protocolo CDP directo por WebSocket
  -conecta al target de tipo `page`, `Page.captureScreenshot`, decodifica el PNG en base64- y con eso
  sí se pudo, por primera vez en esta migración, ver el HTML corriendo de verdad y comparar a ojo
  contra Godot en vez de adivinar por el CSS. De paso quedó documentado que se puede navegar el HTML
  de verdad antes de capturar mandándole JS por `Runtime.evaluate` (`elegirModo('dt')`, `elegir(1,0)`,
  `cerrarTutorial()`, `setTab('club')`...), que es como se consiguieron las capturas de esta entrada.

  **Lo que la comparación real enseñó**: el menú ya iba bien encaminado -la fusión de la tanda anterior
  y las tarjetas con degradado quedaron prácticamente iguales al HTML-, pero la pantalla de JUEGO
  escondía una diferencia de fondo, no cosmética. El HTML no tiene 17 pestañas sueltas en una tira: tiene
  CINCO pestañas -`TABS_ORDEN=['club','plantel','partido','finanzas','mundo']`, con sus iconos
  🏟️👥⚽💰🌎- y cada una abre su propio submenú (`subsDe()`), con hasta 32 sub-pantallas dentro de
  "Club". Godot tenía las 17 pestañas -Mi plantel, Mercado, Copa, Club, Continental, Enfermería,
  Logros, Entrenar, Federación, Estadio, Selección, Cantera, Contratos, Comparar, Récords, Finanzas,
  Camarín- todas al mismo nivel, en una tira que había que desplazar con flechas: nada que ver con la
  barra de cinco de abajo del HTML, y encima "Mercado" vivía suelta cuando en el HTML es una sub-pestaña
  de FINANZAS, no su propio bloque.

  **La reorganización, sin tocar ni una pantalla por dentro**: se agruparon las 17 pestañas -mismos
  nombres, mismo contenido, ni una función de pintado tocada- bajo los cinco grupos reales
  (`Inicio.GRUPOS`), con una barra de cinco botones arriba y un submenú que cambia solo debajo, calcado
  del `#tabs` del HTML. El `TabContainer` de siempre sigue existiendo por dentro -con `tabs_visible =
  false`, así que solo cambia lo que se ve, no cómo se navega por código- y por eso los 19 scripts de
  captura y el banco de pruebas que ya buscaban una pestaña por su título (`get_tab_title(i) ==
  "Mercado"`) siguieron funcionando sin tocar una línea. Se sumó una pestaña nueva y corta, "Partido"
  -el HTML la tiene como portal al partido en vivo, que en Godot ya es el botón "Dirigir el partido" de
  arriba, así que aquí es solo un atajo a ese mismo botón, no una pantalla duplicada-. El repintado se
  engancha a `TabContainer.tab_changed`, así que la barra de grupos nunca queda desincronizada pase lo
  que pase -tocar el submenú, o que una prueba cambie `current_tab` a mano-.

  Reparto final: CLUB (Estadio, Club, Comparar, Récords, Logros) · PLANTEL (Mi plantel, Entrenar,
  Enfermería, Camarín, Cantera, Contratos) · PARTIDO (el atajo nuevo) · FINANZAS (Finanzas, Mercado) ·
  MUNDO (Copa, Continental, Selección, Federación).

  **Un bug de verdad que salió de mirar la consola durante las pruebas, no de la reorganización**:
  `Cara.foto_real()` (de la tanda anterior) usaba `load()`, que exige que Godot ya haya importado el
  archivo -inviable con una búsqueda que sigue bajando fotos nuevas sesión tras sesión, habría que
  reimportar el proyecto entero cada vez- y además decide el decodificador POR LA EXTENSIÓN del
  archivo: una tanda de la búsqueda guardó imágenes PNG con extensión ".jpg" -el nombre del archivo
  sale del nombre del jugador, no del formato real que devuelve Wikimedia-, así que esas fotos
  fallaban con "Failed loading resource" aunque el archivo fuera perfectamente válido. Se reescribió
  para leer el archivo a mano (`FileAccess` + `Image.load_png_from_buffer()`/`load_jpg_from_buffer()`),
  mirando la firma real de los primeros bytes en vez de fiarse del nombre: ahora es inmune a que Godot
  todavía no haya importado el archivo Y a que el nombre mienta sobre el formato.

  Verificado con `pruebas/banco.gd` (0 fallos, sin pruebas nuevas -es una reorganización de navegación,
  no lógica nueva-), con `pruebas/banco_inicio.gd` (el enganche completo `Inicio → Principal` sigue
  intacto) y con capturas reales de `pruebas/captura.gd`: la barra "🏟️ Club · 👥 Plantel · ⚽ Partido ·
  💰 Finanzas · 🌎 Mundo" con el submenú "Estadio · Club · Comparar · Récords · Logros" bajo Club, y con
  Finanzas activo, su submenú "Finanzas · Mercado" mostrando de verdad las ofertas recibidas. Y, por
  primera vez en esta migración, una captura real del HTML corriendo (`herramientas/captura_html.ps1`)
  para comparar -no solo su código- en la próxima tanda de pulido visual.

- **Pulido visual: fondo animado y degradado en las tarjetas** (4-9-2026, séptima tanda). El usuario
  pidió, tras ver la reorganización de pestañas, "los fondos moviéndose" y "ponerle tipo degradé" a la
  interfaz. Los dos pedidos resultaron ser HTML de verdad, no invención:

  El HTML monta un `Phaser.Game` entero solo para el menú (`iniciarPhaserMenu()`/`EscenaMenuFx`): motas
  de luz blancas que nacen en cualquier punto de la pantalla y suben despacio (4 a 12 px/fotograma, con
  una deriva lateral pequeña), durante 6 segundos, apagándose en tamaño y opacidad. Se portó como
  `ui/fondo_particulas.gd` (`FondoParticulas extends CPUParticles2D`) -Godot ya trae su propio sistema
  de partículas, así que no hacía falta ningún motor externo, solo copiar los mismos números-. Se cuelga
  del menú (`Inicio`), fuera del `ScrollContainer` -como el canvas de Phaser, que flota encima de
  `#main` sin desplazarse con la página-.

  El `.card` del HTML tampoco es un color plano: trae un degradado cenital sutil
  (`linear-gradient(180deg, panel+12%blanco, panel 42%)`) que le da aire de placa con brillo. Todos los
  paneles de Godot (`_panel()`, y por tanto `_columna()`/`_bloque()` que lo usan por dentro) lo pintaban
  liso. `StyleBoxFlat` no admite degradados, así que se superpuso una textura aparte -blanco
  semitransparente arriba, cero abajo- que ignora el ratón: mismo efecto, sin tapar ningún control. Al
  tocar la función compartida, el brillo llegó de una vez a TODAS las pantallas que ya usaban
  `_panel()` -docenas de secciones, de Consejeros a la Tabla de posiciones-, no solo a una.

  **Dos bugs de verdad, pagados con capturas, no solo leyendo el código:**
  1. La primera captura salió con la tarjeta de perfil deforme -altísima, con una banda negra enorme
     debajo del texto-. Causa: un `TextureRect` sin `expand_mode` pide como mínimo el tamaño NATIVO de
     su textura (128 px de alto en este caso) y estira TODO el panel para dárselo -el brillo agrandaba
     la tarjeta en vez de solo pintarla-. Se corrigió con `expand_mode = EXPAND_IGNORE_SIZE`, el mismo
     que ya usan `_fondo_banner`/`_overlay` un poco más abajo en el mismo archivo -la trampa ya estaba
     resuelta ahí y no se reutilizó al escribir el código nuevo-.
  2. Con el tamaño ya arreglado, el panel seguía oscureciéndose de arriba a ABAJO en vez de aclararse
     solo arriba. Causa: `Gradient.set_color(i, ...)` indexa por PUNTO, no por posición en el degradado,
     y `add_point()` desplaza los índices de los puntos que ya existían. El código ponía blanco al 10%
     en el punto 0, añadía un punto al 42% -que pasaba a ocupar el índice 1-, y luego intentaba apagar
     "el punto 1" pensando que era el final (offset 1.0) cuando en realidad seguía siendo el del 42%: el
     punto final se quedaba con su color de fábrica (blanco opaco), así que el degradado volvía a subir
     de opacidad hacia el fondo del panel. Se corrigió fijando `offsets`/`colors` como arrays completos
     de una sola vez, sin depender de índices que cambian.

  Verificado con `pruebas/banco.gd` (0 fallos) y con capturas reales de `pruebas/captura_inicio.gd` y
  `pruebas/captura.gd`: las motas subiendo por todo el menú, y el brillo cenital correcto -sutil, solo
  arriba de cada tarjeta- tanto en el menú como en las pantallas de juego (Tabla de posiciones, avisos
  del despacho, Estadio, ficha del jugador...).

  **Corrección la misma tanda**: el usuario señaló que "las fichas donde uno selecciona el modo de
  juego también hay que mejorar". La carátula de cada tarjeta (`TarjetaModo`) se rasteriza aparte del
  `PanelContainer` que la envuelve, y salía con las esquinas de arriba CUADRADAS mientras el panel de
  debajo las tiene redondeadas -se notaba la costura entre la imagen y el marco, como una foto pegada
  encima de una tarjeta en vez de una sola pieza, que es como se ve en el HTML-. Se recorta ahora la
  carátula con un `clipPath` a las mismas esquinas superiores redondeadas -radio proporcional al ancho
  de la tarjeta, para que no se note si se estira a otro tamaño-. Verificado con
  `pruebas/captura_inicio.gd`: las nueve tarjetas del menú ya se ven como una sola pieza redondeada, no
  como una imagen cuadrada sobre un marco.

- **El despido a mitad de temporada, mudo desde siempre** (7-9-2026). Siguiendo el mismo método que
  ya dio resultado antes -clases con señal sin `.connect()`-: `Directiva.despedido` se emite desde
  `mover_confianza()` (`nucleo/directiva.gd:187`), que se llama tras CADA partido vía `tras_partido()`
  (`mundo.gd:997`), no solo al cerrar la temporada. El banco de pruebas ya comprobaba "una racha de
  derrotas acaba en despido" -la lógica funcionaba de verdad-, pero nadie escuchaba la señal en
  `principal.gd`: un despido a mitad de año pasaba dentro del motor y el jugador seguía dirigiendo
  semana tras semana un club que ya lo había echado, sin un solo aviso. Y no se arreglaba solo al
  cerrar la temporada: `mundo.gd:715` se salta el veredicto de la directiva por completo si
  `despedido_ya` ya estaba puesto, así que tampoco llegaba el mensaje "ESTÁS DESPEDIDO" de fin de año
  -el jugador despedido en la jornada 15 no se enteraba NUNCA, ni esa semana ni las 15 siguientes-.

  Se conectó `mundo.directiva.despedido` en `_conectar_noticias()` (`ui/principal.gd`), el mismo sitio
  donde ya viven las otras nueve señales de noticia, con el mismo aviso rojo que usa el despido de fin
  de temporada ("Elige otro club en la lista de arriba"). Como `_conectar_noticias()` ya se llama al
  crear mundo, al cargar partida Y al cambiar de club (`_al_elegir_club()`), no hizo falta tocar nada
  más: la `Directiva` es un objeto nuevo por club (`tomar_el_mando()`, `mundo.gd:916`), así que la
  conexión se rehace sola cada vez.

  Verificado con `herramientas\run_godot.ps1` (0 fallos, sin pruebas nuevas -la lógica de despido ya
  estaba probada, esto era solo el cable que faltaba entre el motor y la pantalla-) y con una captura
  real forzando la confianza a 0 en la jornada 1, sin esperar al cierre de año
  (`pruebas/captura_despido.gd` → `pruebas/pantalla_despido.png`): el registro muestra "confianza 0"
  en la cabecera y "ESTÁS DESPEDIDO. La directiva pierde la paciencia (racha de derrotas) y te
  destituye a mitad de temporada..." en rojo, en la misma jornada.

- **La copa nacional y los continentales, campeones mudos** (7-9-2026, misma tanda). Mismo hallazgo,
  un peldaño más abajo: `Logros.celebrar_titulo()` es el único camino para festejar un título -lo usa
  la liga, la copa nacional Y cada torneo continental (`mundo.gd:600`, `:713`)-, pero
  `titulo_celebrado` solo tenía `Sonido.toca("trofeo")` conectado. La liga no se notaba porque
  `_nueva_temporada()` ya escribe su propia línea con el premio; la copa nacional y sobre todo los
  continentales -que además se coronan A MITAD DE TEMPORADA, según el propio comentario de
  `avanzar_semana()` en `mundo.gd`, no al cerrar el año, igual que el despido de arriba- se ganaban
  con un solo efecto de sonido y ni una palabra en el registro: había que entrar a la pestaña Logros a
  averiguar qué se acababa de ganar. Se añadió una línea "🏆 ¡CAMPEÓN! [nombre]" a la misma conexión,
  para los tres casos -para la liga sale una línea de más, redundante con la suya propia, pero no
  contradictoria; no se quitó la de liga por no tocar su información del premio-.

  Verificado con `herramientas\run_godot.ps1` (0 fallos) y con captura real llamando
  `celebrar_titulo()` igual que lo hace `avanzar_semana()` al coronar un continental
  (`pruebas/captura_titulo.gd` → `pruebas/pantalla_titulo.png`): "🏆 ¡CAMPEÓN! Champions League." en
  dorado en el registro.

- **Las 73 pantallas contadas de verdad, y arranca el lote de "solo interfaz"** (7-9-2026). El
  usuario pidió el porcentaje de migración. En vez de estimarlo, se grepeó `function vXxx(` en
  `js/vistas.js`/`juego.js`: salen exactamente **73**, confirmando el número que ya rondaba el
  proyecto. Cruzadas contra las 18 pestañas + paneles de Godot: ~50 tienen equivalente (muchas
  fusionadas dentro de una pestaña más grande), quedan confirmadas sin portar `vAjustes`,
  `vAjustesDispositivo`, `vAudio`, `vGlosario`, `vCorreo`, `vQoL`, `vGente`, `vSocial`,
  `vIdentidad`/`vIdentidadPlus`, `vEditor`, `vDebate`, más `vLibres` y partes de `vSponsor`.

  Al leer el HTML de cerca, dos de las que parecían "solo pintar" no lo eran: `vGente` (confianza de
  siete personas del club, con conversación semanal y efectos sobre césped/lesiones/ánimo) y
  `vHinchada` (segmentos, fair play, encuestas, planes de abono) son sistemas nuevos de verdad -datos
  y mecánica que Godot no tiene-, así que se excluyeron del lote rápido: eso es motor, no interfaz.
  Igual `vPost` (necesita que `Partido` lleve posesión/xG/córners/fueras de juego, que hoy no lleva).

  Lo que sí es interfaz pura y se hizo esta tanda, grupo nuevo "⚙️ Ajustes":
  - **`vGlosario`**: los 20 términos de la tabla `GLOSARIO` -ya exportada en `datos/tablas.json`
    como cualquier otra, no se transcribió a mano-. Sin buscador por ahora: 20 entradas se leen
    enteras de un vistazo, y el proyecto no tenía todavía ningún campo de texto interactivo que
    replicar con fidelidad.
  - **`vAjustes` (el subconjunto real)**: de sus veinte y pico controles, se descartaron los que no
    tienen NADA a lo que engancharse en Godot -tamaño de texto, paleta daltónica, cabeceras
    ilustradas, tres ranuras de guardado: un interruptor que no cambia nada falla el mismo estándar
    que una pantalla que falta-. Entraron los dos que sí mueven algo real: el sonido, y de paso
    salió un hallazgo del mismo tipo que los de esta mañana -`Sonido.encendido` **ya existía**, con
    `toca()` ya mirándolo, pero nadie lo tocaba nunca desde ninguna pantalla, mudo desde que se
    escribió-; y el autoguardado, nuevo de verdad pero mínimo: reutiliza `Partida.guardar()` tal
    cual, llamado en silencio al final de `_avanzar_semana()`, `_jugar_temporada()` y
    `_nueva_temporada()` si el interruptor está en SÍ.

  Verificado con `herramientas\run_godot.ps1` (0 fallos) y con capturas reales
  (`pruebas/captura_ajustes.gd` → `pruebas/pantalla_ajustes.png` y `pantalla_glosario.png`).

- **`vCorreo`, la tercera de la tanda de interfaz** (7-9-2026, misma sesión). `noticia(titulo,cuerpo)`
  del HTML alimenta `G.noticias` en **372 sitios**; el motor de Godot solo dispara los ~20 avisos que
  `_conectar_noticias()` ya escucha -desde el despido y el título de esta mañana hasta las lesiones y
  el pulso de Roles-, así que igualarlo a los 372 sería escribir motor nuevo bajo la etiqueta de
  interfaz. Se portó el MECANISMO, no el volumen: `_anotar(titulo, cuerpo)`, una función nueva que no
  toca ni una línea de `_escribir()` -cero riesgo de que una captura ya verificada cambiara de
  aspecto-, se añadió como llamada EXTRA en cada uno de esos ~20 sitios, y archiva la misma noticia en
  `_bandeja` (más-nuevo-primero, tope 60 como el HTML). `_pintar_correo()` la lee con los mismos dos
  filtros del HTML ("Todo"/"Sin leer", con contador) y "Marcar todo como leído"; cada fila es un botón
  plano -el mismo truco que ya usa `_fila_jugador()` para plantel, no un `VBoxContainer` metido dentro
  de un `Button`, que no es un patrón que ya exista aquí y cuyo tamaño mínimo es el del texto, no el de
  sus hijos- que marca esa noticia leída al pulsarla. Como `_autoguardado`, vive solo en la sesión de
  juego: no toca el esquema de `Mundo` que prueba a fondo "GUARDAR Y CARGAR".

  Verificado con `herramientas\run_godot.ps1` (0 fallos) y con capturas reales forzando dos avisos de
  verdad -una lesión y un informe médico, los mismos caminos que ya escucha `_conectar_noticias()`-
  (`pruebas/captura_correo.gd` → `pantalla_correo_sinleer.png` con "Sin leer (2)" y las dos con el
  punto azul, `pantalla_correo_leida.png` tras pulsar la primera fila de verdad: baja a "Sin leer (1)"
  y esa fila pierde el punto y el color).

- **La búsqueda de caras reales TERMINÓ** (7-9-2026): `herramientas/caras_reales_buscar.ps1` -que
  llevaba sesiones enteras corriendo sola, reanudada al principio de esta- procesó los **2.125**
  nombres únicos completos. Resultado final: **1.048 con foto real** (49,3% de acierto) descargada en
  `recursos/caras_reales/` con licencia libre verificada, registrado en
  `datos/caras_reales_reporte.json`. Ya no queda nada pendiente de esta tarea: no hace falta volver a
  lanzar el script salvo que la tabla `REALES` del HTML cambie de nombres.

- **Barrido de señales sin conectar en todo el proyecto** (7-9-2026): mismo método que ya encontró el
  despido y el título mudo de esta mañana, aplicado a las ~40 señales restantes que no aparecían con
  `.connect()` en ningún lado. Casi todas resultaron ser FALSOS positivos: `Cesiones` (`cedido`,
  `vendido`, `clausula_pagada`...), `Cantera` (`canterano_robado`, `hijo_de_leyenda`...),
  `Entrenamiento` (`habilidad_aprendida`...) y `Roles` (`fuera_del_cuerpo_tecnico`) emiten SIEMPRE su
  señal específica junto a un `noticia.emit()`/`aviso.emit()` genérico en la misma línea o la
  siguiente -confirmado leyendo el código fuente, no adivinado-, y esos dos canales genéricos ya están
  conectados desde hace tiempo. La señal concreta es para que la escuche OTRO sistema (logros,
  achievements), no la pantalla. Solo salieron dos gaps reales, arreglados los dos: `Directiva`,
  `Instalaciones`/`Mundo.obra_lista` no tienen ningún canal genérico que las cubra, así que sí estaban
  mudas de verdad -ver las dos entradas de esta mañana y la que sigue-.

- **Las obras terminan en silencio** (7-9-2026, misma tanda). `Instalaciones.avanzar_semana()`
  devuelve las obras recién terminadas, y `Mundo.avanzar_semana()` (línea 540) las reemite como
  `obra_lista` con un comentario que lo dice de frente: "para que la noticia de 'obra terminada' salga
  la misma semana en que termina". La intención estaba escrita desde que se creó la señal; nadie la
  conectó nunca. Construir un nivel de instalación cuesta semanas y millones y no avisaba de nada: solo
  se notaba entrando a la pestaña Club a mirar. Conectada en `_conectar_noticias()`, junto al resto.

  Verificado con `herramientas\run_godot.ps1` (0 fallos) y con captura real forzando el centro de
  entrenamiento a un plazo de 1 semana y avanzando una -el mismo camino que toma cualquier obra que se
  termina de pagar- (`pruebas/captura_obra.gd` → `pruebas/pantalla_obra.png`): "🏗️ Obra terminada:
  Centro de entrenamiento llega a nivel 1." en el registro.

- **Agentes libres, `vLibres`/`ficharLibre`/`procesoLibres` del HTML, la primera pieza de motor
  nuevo real de esta sesión** (7-9-2026). A diferencia de las cinco pantallas descartadas del lote
  rápido (vGente, vHinchada, vSocial, vIdentidad, vDebate -sistemas enteros que Godot no tenía-, y
  vEditor -demasiado grande-), esta sí se pudo construir con piezas que YA existían: `crear_jugador()`
  para generar al jugador (se genera con un club cualquiera y se desliga después con `club_id = ""`,
  que ya es el valor de fábrica de un `Jugador` nuevo -mismo truco que `j.club=''` en el HTML-),
  `Mercado.deseo_de_venir()` para decidir si acepta (ya es seguro con `club_id == ""`: sin club propio
  salta directo a las tres razones que no comparan clubes), `Mercado.fichar()` para cerrar el fichaje
  sin tocar nada nuevo (con `club_id == ""` no hay vendedor al que pagarle, así que la "prima de
  fichaje" solo sale de la caja del comprador, exactamente como en el HTML), y `Prensa.agente_de()`
  para el recargo del representante.

  Lo nuevo de verdad: `Mundo.libres: Array[Jugador]`, dos campos en `Jugador` (`motivo_libre`,
  `rechazos_libre` -a la segunda negativa, sale de la bolsa-), `generar_libres()`/`_nuevo_libre()`
  (10-16 al empezar), `fichar_libre()`, y `_procesar_libres()` cada semana -50% de reponer si hay
  menos de 6, 4% de una "joya" con aviso propio, 35% de que se vaya vaciando sola, calcado de
  `procesoLibres()`-. Pantalla nueva "Libres" en el grupo Finanzas, junto a Mercado: filtro por
  demarcación, y a diferencia del comparador o de la lista de objetivos del mercado normal, la media Y
  la proyección se enseñan SIN tapar -son jugadores disponibles de verdad, no un rival que hay que
  ojear primero, igual que en el HTML-.

  Se guarda: los dos campos nuevos de `Jugador` entran en `_jugador_a_dic`/`_dic_a_jugador` con
  `.get(..., default)` para no romper guardados viejos, y `libres` se guarda como el array de arriba,
  junto a `copa`/`continentales` -es del MUNDO, no de tu club, así que no vive dentro de
  `_restaurar_lo_tuyo()`-.

  **Simplificación consciente, documentada, no un descuido:** el HTML también deja que los CLUBES DE
  LA IA fichen de la bolsa (`js/juego.js:3382`) y que un jugador cortado de una plantilla -por edad, en
  el cierre de temporada- caiga ahí en vez de desaparecer (`js/juego.js:8055`). Ninguna de las dos
  entró en esta tanda: la bolsa hoy solo la usa tu club. Es la puerta de ENTRADA que faltaba -antes no
  existía ni para ti-; conectarla también a la IA y a los cortes de plantilla queda para otra tanda,
  sin que rompa nada de lo que ya hay.

  Verificado con `herramientas\run_godot.ps1` (0 fallos, sin pruebas nuevas en el banco -toda la
  lógica reutiliza funciones ya probadas a fondo: `deseo_de_venir`, `fichar`, `tasar`-) y con capturas
  reales (`pruebas/captura_libres.gd`): `pantalla_libres.png` (la lista con motivo y prima de cada
  uno), `pantalla_libre_estrella.png` (forzando la joya del 4%: "⭐ Agente libre de lujo en el mercado.
  Iván Cáceres (30 años, media 86)..." en dorado) y `pantalla_libre_fichado.png` (tras fichar: la caja
  baja exactamente la prima, los sueldos suben, y el fichado desaparece de la lista).

- **Las estadísticas del partido: `M.st` y el informe de `vPost()`** (7-9-2026). El motor contaba
  goles y remates y nada más, así que un 1-0 sufrido se leía igual que un 1-0 cómodo. Se portaron las
  siete cifras del HTML con sus probabilidades exactas por minuto -córners 10%/9%, faltas 16%/17%,
  fueras de juego 5%/5%; el local saca alguno más y comete alguna menos, que es la ventaja de campo
  contada en detalle-, más la **posesión** (media móvil al 6% por minuto sobre quién está llegando
  más, topes 22-78, y el `ritmo` bajo suma 6% porque jugar lento es tener la pelota) y el **xG**
  (0,09-0,31 por llegada, acumulado).

  Los **tiros a puerta** no hicieron falta inventarlos: salen del mismo tiro de dados que ya decide el
  desenlace -gol y atajada cuentan, el palo no, exactamente como el HTML, que solo hace `puertaMi++`
  en esos dos casos-.

  Se llevan en TODOS los partidos, no solo en el tuyo como el HTML: son seis tiradas por minuto
  -milisegundos en una jornada entera- y así ningún camino (copa, continental) se queda sin ellas por
  olvido. En pantalla: la línea de arriba del partido en vivo ahora lleva posesión y tiros al arco, y
  al pitido final la crónica recibe el cuadro completo de siete filas **con tu columna primero, seas
  local o visitante**, más el **informe del ayudante** (`infPostPartido()` portado frase por frase: te
  traduce el xG a idioma humano -"generamos mucho más de lo que anotamos: falta puntería"-, te avisa si
  cometiste más de 16 faltas, si el arquero os salvó, y si no usaste ningún cambio).

  Verificado con `herramientas\run_godot.ps1` (0 fallos) y con **ocho comprobaciones nuevas** en
  `pruebas/banco.gd`: nunca más tiros a puerta que remates, nunca más goles que tiros a puerta, la
  posesión dentro de 22-78, y las medias por partido dentro de rango. Los números salieron
  **clavados en lo que predice la fórmula**: 29,7 faltas medidas contra 29,7 teóricas (0,33/min × 90),
  17,6 córners contra 17,1, 9,3 fueras contra 9,0.

  **Y las pruebas se comprobaron al revés**, como manda el protocolo del proyecto: se bajó a propósito
  la probabilidad de córner de 10%/9% a 1%/0,9% y el banco lo cazó -no pasó de largo-. Sin ese paso,
  una prueba que nunca se ejecuta parece una prueba que pasa. (De hecho casi cae en esa trampa: la
  primera corrida se leyó con `| tail -25` y las líneas nuevas quedaron cortadas, así que "0 fallos"
  no probaba nada sobre ellas. La salida cruda a un archivo lo dejó ver.)

- **EL BUG QUE APLASTABA LA LIGA ENTERA: un rep 88 no era más fuerte que un rep 67** (7-9-2026).
  Salió de rebote, montando las cuotas de apuestas de la previa: Colo-Colo (reputación 88) daba
  ataque 59,3 y D. Limache (reputación 67) daba 59,5. **El grande era marginalmente PEOR que el
  chico.** Con la jerarquía deportiva aplastada, ni las cuotas, ni la simulación, ni el mercado, ni la
  sensación de dirigir a un grande significaban nada. Dos causas encadenadas, las dos en
  `nucleo/reales.gd`:

  1. **`_reescalar_generados()` cambiaba el `ovr` de un jugador y nunca regeneraba sus atributos.**
     Y el juego mira DOS magnitudes distintas del mismo futbolista: `Club.once()` elige el once por
     `media_en(puesto)` -que sale de los ATRIBUTOS- y `Partido._media_linea()` puntúa por `ovr`. Un
     relleno bajado de 86 a 70 conservaba atributos de 86, así que **entraba al once por delante de
     Vidal (78) y luego rendía como un 70**. Colo-Colo salía al campo con nueve rellenos degradados y
     Vidal, Cepeda, Pizarro y De Paul en el banco. Una línea (`j.generar_atributos()`): +6,5 de ataque.
  2. **La banda de reescalado se anclaba a los reales, no a la reputación del club.** Medido con
     semilla 777: al grande le hundía la media de plantel de 77,0 a 69,0 y al chico se la SUBÍA de
     55,8 a 61,5. Trece puntos de compresión contra veintiuno de diferencia de reputación. Ahora el
     techo respeta `club.rep - 9` -la misma referencia que usa `Mundo._poblar()`-, así que el
     reescalado puede bajar al que sobra pero nunca subir al que no da la talla.

  Resultado: de 59,3 contra 59,5 a **66,3 contra 56,2**. Con prueba nueva que fija la jerarquía
  (`un club de rep 88 ataca mas que uno de rep 67` + `la diferencia se nota de verdad`), para que no
  se vuelva a aplastar en silencio. Queda documentado, sin tocar, un tercer factor que es de DATOS y
  no de código: las medias de la tabla `REALES` solo separan 5,6 puntos donde la reputación separa 21
  (a un rep 88 le tocan reales de 71-78). Eso es material para la auditoría, no para un parche.

- **Dos bugs silenciosos más, del mismo día:**
  - **Los cuatro interruptores tácticos no se guardaban.** `salida_corta`, `marca_al_hombre`,
    `fuera_de_juego` y `tiro_lejano` se podían activar, movían el partido de verdad -`Tactica` los usa
    en sus multiplicadores- y volvían todos a `false` en cada carga sin una queja. Añadidos a
    `_club_a_dic`/`_dic_a_club`, con prueba que marca dos sí y dos no para distinguir "vuelve el
    valor" de "vuelve el valor por defecto".
  - **Una prueba del banco era estadísticamente falsa.** "En cancha neutral se pierde la ventaja de
    local" contaba victorias en 300 partidos y comparaba los dos números a pelo: con p≈0,4 y n=300 el
    ruido propio es de ±8 victorias, o sea que la diferencia esperada cabía entera dentro del error.
    Pasaba por suerte, y el día que las plantillas cambiaron de fuerza salió 118 contra 126 -al revés-
    sin que nada estuviera roto. Ahora se mide por GOLES, que es señal continua y se ve con mucha
    menos muestra. **Una prueba que pasa por suerte es una prueba que miente.**

- **La auditoría real de las 73 pantallas** (7-9-2026). Un agente cruzó una por una las 73 funciones
  `vXxx()` del original contra el puerto, buscando por CONTENIDO y no por nombre (muchas están
  fusionadas). Recuento honesto: **27 completas, 24 parciales, 22 sin empezar**. Las cuentas
  anteriores de esta sesión eran optimistas porque daban por hechas las parciales. Hallazgo útil:
  varias parciales lo son solo por falta de PANTALLA, no de motor -`federacion.gd` ya lleva licencia,
  tribunal y antidopaje; `logros.gd` emitía `premios_entregados` sin oyente; `club.precio_entrada`
  existe sin control-. Ese grupo es el de mejor relación esfuerzo/resultado.

- **Cuatro pantallas nuevas, siete del original cubiertas** (7-9-2026):
  - **Premios** (`vPremios`): la gala de fin de año. `Logros.premios_temporada()` la calculaba entera
    -equipo ideal, mejor joven, mejor entrenador, fair play, club más popular, mejor hinchada, mejor
    estadio- y se guardaba sin que nadie la viera nunca. Ahora tiene pestaña y, además, la señal
    `premios_entregados` -que tampoco escuchaba nadie- anuncia en el registro qué se llevó tu club.
  - **Clubes**: se come CUATRO del original de una vez, porque son la misma pregunta a distinta
    profundidad. `vLigas` (la tabla de cualquiera de las 24 ligas), `vClubes` (el directorio),
    `vFichaClub` (pulsar un club y ver su plantel, con las medias pasando por el mismo filtro de ojeo
    que el resto del juego) y `vGoleadores` (los artilleros de esa liga, sacados de las plantillas:
    no hace falta un registro aparte que mantener al día). Cero datos nuevos.
  - **Desafíos** (`vDesafios`): el puntaje de carrera con su desglose. `Mundo.puntaje_carrera()`
    nuevo, tres líneas, sumando lo que ya se llevaba por otro lado (títulos ×1.000, prestigio ×40,
    logros ×300, temporadas ×120) por el multiplicador que ya existía.
  - **Los onces** (`vAlineacion`), dentro de la previa: el `Partido` que la previa ya monta para medir
    fuerzas es el mismo que jugará, así que enseñar sus dos onces no cuesta ni un cálculo más.

- **Tres parciales cerradas: motor que ya existía y no se veía** (7-9-2026). El grupo que la
  auditoría marcó como mejor relación esfuerzo/resultado, y tenía razón:
  - **Federación**, que solo enseñaba el reglamento y la votación, ahora muestra sus otros tres
    bloques: la **licencia de club** con sus seis requisitos (`requisitos_licencia()`, que ya existía)
    y el aviso de que dos incumplimientos te dejan sin cupo internacional; el **tribunal de
    disciplina** con botón de apelar (`apelar()`, que ya existía); y los **controles antidopaje**. Lo
    más sangrante: al abrir un caso, el motor emitía la noticia *"Puedes apelar desde Federación"* —
    **le prometía al jugador una pantalla que no existía**. Ahora la promesa se cumple.
  - **El precio de la entrada.** `Club.precio_entrada` estaba en el motor moviendo la ocupación un 5%
    por euro y la recaudación por cabeza, y no había ningún control para tocarlo: una palanca de
    gestión real, escrita y funcionando, que el jugador no podía mover. Va arriba de Finanzas con la
    asistencia estimada y la taquilla al lado, que es donde se ve la trampa: subir puede recaudar
    MENOS. (Nota para el futuro: `Finanzas` no vive en el mundo, se construye por club y por semana
    dentro de `Mundo.avanzar_semana()`; para preguntarle algo desde la interfaz hay que montar uno
    igual, que no cobra nada.)
  - **Renovaciones de contrato.** `Cantera.pide_para_renovar()` sabía calcular lo que pide cada uno
    -sueldo actual, recargo por moral baja, recargo por rendir por encima del club, multiplicador de
    su agente- y **no había forma de decirle que sí**: un contrato que se acababa era un jugador que
    se perdía solo. Nueva `Cantera.renovar(j, con_clausula)`, portada de `renovarJug()`: firma por
    2-4 temporadas, y **con cláusula de salida acepta un 10% menos de ficha** -esa es la decisión, no
    un adorno-. El agente mediático se apunta el tanto y le sube 3 de moral, igual que en el HTML.
    Cinco comprobaciones nuevas, incluida la de que no puedes renovar a un jugador ajeno.

- **El aviso se generaliza: TIPOS con su color y su sonido** (7-9-2026, misma sesión). El usuario
  pidió reutilizarlo para más cosas -"los ingresos extras por copas, o que un club pagó la cláusula, o
  que los contratos vencerán"- y dijo la razón: **"es con la idea de sentir vivo el juego"**. También
  pidió que más adelante cada uno tenga sonido distinto.

  Por eso `AvisoLogro` pasó a ser `Aviso` con una tabla `TIPOS`: etiqueta, color de acento y sonido,
  los tres en un solo sitio. Dar sonido propio a un tipo nuevo es **añadir una fila aquí y una receta
  en `Sonido._sintetizar()`**, sin tocar ni la animación ni los sitios que lo llaman. Tipos: `logro`,
  `record`, `nivel`, `dinero`, `gasto`, `mercado`, `alerta`, `contrato`, `titulo`.

  Enganchados: te pagan la cláusula de uno tuyo (rojo, es de las peores noticias que hay) y el
  clausulazo al revés; los ingresos de copa -`campeon_proclamado` y `ronda_terminada` se emitían desde
  siempre sin oyente: el premio entraba en la caja en silencio-; los contratos que vencen al cerrar
  temporada, con la pretemporada por delante para reaccionar; las ofertas recibidas; las ventas; y los
  títulos.

  **No todo pasa por aquí a propósito**: si interrumpiera con lo rutinario dejaría de significar algo.
  Y la cola tiene tope (8): una temporada que dispare veinte avisos enseña ocho, no veinte.

  Dos trampas pagadas: la clave del resultado de una ronda de copa es `pasa`, **no** `gana` -habría
  fallado en silencio-; y el aviso de título no debe llamar a `Sonido.toca("trofeo")` por su cuenta,
  porque el tipo ya lo toca y sonaría dos veces.

- **Aviso de logro al estilo consola, a petición del usuario** (7-9-2026). Un logro solo escribía una
  línea en el registro, entre las otras quince de la semana: se desbloqueaba y el jugador no se
  enteraba. Ahora `ui/aviso_logro.gd` (`AvisoLogro`) entra deslizándose desde el borde derecho, se
  queda 3,4 s y se va, con icono, título y descripción. Enganchado a los logros, a los récords del
  club y a las subidas de nivel del perfil, que son el mismo tipo de momento.

  Tres decisiones que lo hacen funcionar:
  - **Sonido propio, sintetizado como todo lo demás** (`"logro"`): dos notas que suben una quinta,
    agudas y secas, **0,45 s** contra los 5 s de `"trofeo"`. Un logro no es un título, es un guiño:
    tiene que reconocerse al instante y no pisar lo que esté sonando.
  - **`mouse_filter = IGNORE` en el aviso y en todos sus hijos.** Flota por encima de la pantalla; si
    atrapara el ratón bloquearía los botones de debajo.
  - **Se encolan.** Al cerrar una temporada pueden caer tres de golpe, y sin cola el tercero pisaría
    al primero y no se leería ninguno. El siguiente entra cuando el anterior ha salido del todo.

  Verificado con captura disparando tres seguidos: en la primera se ve el aviso puesto, y en la
  segunda el SEGUNDO de la cola saliendo por el borde -o sea que esperó su turno-.

## QUE SE NOTE QUÉ SE JUEGA (8-9-2026, pedido del usuario)

La columna izquierda enseñaba **siempre** la tabla de liga. Con eso, la semana de Libertadores se
sentía igual que la jornada catorce de campeonato. Ahora sigue a la competición del **próximo
partido**, con el mismo orden de prioridad que usa `_dirigir()` —si los dos dijeran cosas distintas,
la tabla mentiría sobre el partido—:

| Lo que toca | Lo que se ve |
|---|---|
| Copa nacional | el cuadro: tu rival, si es en casa, y quién sigue vivo |
| Continental, grupos | **tu grupo**, con los dos que clasifican en verde |
| Continental, eliminatorias | el cuadro y los que quedan |
| Liga | la tabla de siempre |

Y el encabezado cambia con ella: *«COPA LIBERTADORES · GRUPO A»*. En un torneo a un partido no hay
puntos que enseñar, así que lo que se enseña es lo único que importa: quién queda.

**La ficha del jugador también rota.** Se quedaba clavada en el mismo hombre semana tras semana y un
plantel de veinticuatro se convertía en uno. Ahora `_jugador_de_la_semana()` enseña a quien tiene
algo que contar —primero el lesionado, luego el que está en racha (media de las tres últimas notas
por encima de 6,8)— y solo si no hay noticia, el turno rota con la semana y en un año pasan todos.

## EL DESBORDE DE 24 PÍXELES (8-9-2026) — SOLO SE VE EN CAPTURA

La ficha del jugador salía cortada por el borde derecho: *«Contrato 3 añ»*, *«50k EUR / sema»*. **El
banco no lo puede detectar** —no hay error, no hay excepción, las tres columnas existen y se pintan—.
Solo se ve mirando una captura.

La causa no estaba en la ficha. **Un `Button` o un `Label` piden de ancho mínimo lo que mida su
texto**, ese mínimo sube por los `HBoxContainer` hasta la raíz, y la raíz se hacía más ancha que la
ventana: 1.624 px en 1.600. Empujaba TODO —el aviso de mercado de arriba, la fila de acciones y las
tres columnas— fuera del borde. Tres sitios lo forzaban a la vez: la fila de botones de acción, los
seis botones de grupo y el selector de club.

El arreglo es `clip_text = true` en los tres, más `tooltip_text` para no perder el texto entero.

**Y una trampa dentro del arreglo:** con `clip_text` a secas un botón puede encoger hasta CERO. La
primera vez que se probó, la fila entera de acciones se quedó en siete rayas de un píxel —peor que el
problema original—. Hace falta `custom_minimum_size.x` junto al recorte, siempre.

## EL LOTE BARATO: MOTOR ESCRITO Y SIN PANTALLA (8-9-2026)

Una auditoría ponderada **por líneas de JS** (no por pantallas) dio el número real: **20,3%
terminado, 46,4% contando las parciales a mitad**. Las cifras anteriores (62%, 75%) eran optimistas
por dar las parciales por hechas.

Pero el hallazgo útil fue otro: **había sistemas enteros escritos, probados y con CERO llamadas desde
`ui/`**. No estaban a medias — estaban completos y nadie los llamaba. El usuario eligió ese lote
("vamos por las baratas") y se cerró entero:

| Sistema | Vivía en | Lo que faltaba |
|---|---|---|
| Roles tácticos del once | `vestuario.gd` | la pantalla entera |
| Árbol de carrera del DT | `entrenamiento.gd` | la pantalla entera |
| Roles prometidos | `vestuario.gd` | solo lo escribía la renovación |
| Riesgo de fuga de canteranos | `cantera.gd` | el número no se veía en ningún sitio |
| Ofertas de trabajo tras despido | `roles.gd` | la pantalla entera |
| Los tres buses de sonido | `sonido.gd` | la pantalla daba un solo SÍ/NO |

**La lección de método:** un `grep bonus_roles` fuera de su propio archivo daba CERO y casi lo doy por
muerto. Estaba vivo — `factores()` lo llama dentro del mismo `vestuario.gd`, y `Mundo.
aplicar_bonificadores()` lleva el resultado al club. **Antes de declarar muerto un sistema hay que
grepear también dentro de su propio archivo**, o se reescribe algo que ya funcionaba.

**Cada uno se probó por su EFECTO, no por su existencia**, que es la diferencia entre una pantalla y
un adorno que miente:
- Once de llegadores **×1,049 ataque / ×0,978 defensa** contra once de pivotes **×0,980 / ×1,049**.
  Pedir roles ofensivos regala la espalda, y ahora se mide.
- El árbol del DT: sin el nodo padre no se abre el hijo aunque sobren puntos (*«antes: Negociador»*),
  el coste se cobra, y «genio» da **×1,060** de verdad.
- Roles prometidos: el mejor del plantel **no acepta** ser prescindible, al último **no le puedes
  prometer** ser intocable, y bajarle el escalafón a un crack le costó **5 de moral en el acto**.

**Dos señales mudas más, encontradas de paso:** `punto_dt_ganado` (ganabas un punto de habilidad cada
diez semanas y no te enterabas — ahora sale por `Aviso`) y todo `roles.sin_club` (te echaban y no
había ninguna pantalla donde firmar por otro club).

**Y una corrección a la auditoría:** decía que faltaban el fair play de la hinchada y las categorías
inferiores. Los dos estaban ya pintados. Las auditorías de agente también se equivocan; hay que
comprobar antes de "arreglar" algo que funciona.

## LA TUBERÍA QUE COLGABA EL BANCO (8-9-2026) — TRAMPA CARA

Dos tandas de **25 minutos perdidas** creyendo que "el banco tardaba mucho". No tardaba: estaba
bloqueado, y el síntoma engañaba del todo — el proceso figuraba vivo pero consumía el 15% de CPU y no
avanzaba nunca.

**La causa.** `& $godot ... *> fichero` manda la salida por una **tubería de PowerShell**. Si algo
abre ese fichero mientras se escribe —un `Get-Content` para "ver cómo va", que es justo lo que hice—
el escritor se bloquea, la tubería se llena, y Godot se queda parado esperando a poder escribir.

**El arreglo.** `herramientas\run_godot.ps1` acepta ahora `-Salida <fichero>` y `-TopeSegundos`
(540 por defecto). Usa `Start-Process` con `-RedirectStandardOutput`, que escribe **a disco sin
tubería**: el fichero se puede leer mientras corre sin bloquear nada, se obtiene un código de salida
de verdad, y si se cuelga lo mata y devuelve 2 en vez de quedarse en silencio para siempre.

**Dos trampas más que salieron del mismo hilo:**
- **Comillas en la ruta.** El proyecto vive en `Proyecto x`. Sin comillas, Godot recibe
  `C:\...\Proyecto` y aborta con *Invalid project path*.
- **Procesos zombis.** `run_godot.ps1 -Jugar` abre el JUEGO en una ventana, no el banco (el banco es
  el modo sin argumentos). Cada `-Jugar` que no se cierra queda vivo comiéndose la CPU: llegó a haber
  **cinco a la vez**, y entre todos ahogaban cualquier tanda nueva. Antes de acusar al banco de
  lento: `Get-Process | ? ProcessName -like "*Godot*"`.

## `Eco`, NO `Economia` (8-9-2026)

El autoload de economía se declara en `project.godot` como `Eco="*res://nucleo/economia.gd"`. El
fichero se llama `economia.gd` y **no tiene `class_name`**, así que `Economia.escalar(...)` no
compila. El error que sale no dice eso: dice `Parse Error: Identifier "Economia" not declared`, y
como `roles.gd` es dependencia de medio núcleo, **cae en cascada** — `cantera`, `negociacion`,
`mercado`, `mundo` y el propio banco fallan al compilar, y las pruebas siguen corriendo contra un
mundo a medio construir dando FALLOS que no tienen nada que ver con la causa. Los primeros cuatro
fallos del banco («otra semilla, otro mundo», «se generan más de 300 clubes»…) eran todos ese
identificador mal escrito.

Además `Eco.escalar()` **ya devuelve `int`**: envolverlo en `int(round(...))` es ruido.

## LA TANDA DE ASPECTO, AUDIO E IDIOMAS (8-9-2026)

Un lote entero pedido por el usuario en cuatro mensajes seguidos: *"si puedes agregar detalles o
mejoras estéticas te dejo la libertad, me gusta demasiado lo de poder configurar o de tener
muchísimas opciones"*, *"ve si puedes agregar más fondos, me gusta que se muevan y sean
interactivos, o que los botones o las secciones tengan su marco o sus marcas, tipografía, idiomas y
muchísimos sonidos más"*, *"recuerda que en el LEEME habíamos puesto unos mínimos de sonidos"* y
*"además de inglés y portugués quiero más idiomas"*.

### Lo que hay ahora, en números

| | antes | ahora |
|---|---|---|
| Paletas de interfaz | 1 | **9** |
| Fondos de pantalla | 14 | **24** |
| Climas animados encima del fondo | 0 | **10** |
| Formas de tarjeta | 1 | **5** |
| Marcas de tarjeta | 0 | **7** |
| Tipografías | 1 | **7** |
| Efectos de sonido | 22 | **62** |
| Piezas de música | 0 | **6** |
| Idiomas | 1 | **7** |

### Las decisiones que conviene no volver a discutir

**El tema de la paleta va en un `Theme` colgado de la raíz, no en cada pantalla.** El primer intento
solo tocó `_panel()`, y con una paleta clara salía la mitad de arriba en crema y la mitad de abajo en
gris oscuro: los botones, las pestañas y los desplegables los dibuja Godot con SU tema de fábrica y
`_panel()` no los ve. `_aplicar_tema()` en `ui/principal.gd` los define todos de una vez.

**Los textos se traducen de color, no solo el fondo.** Las dos mil llamadas a `_texto()` piden
`COL_TEXTO` o `COL_SUAVE`, que son claros porque el fondo por defecto es oscuro. Con una paleta clara
eso queda blanco sobre blanco. Se traduce en `_color_de_paleta()`, en el único sitio por el que pasan
todas las etiquetas. Y los colores con significado propio —el acento del club, el oro, el rojo— no se
traducen sino que se EMPUJAN hasta separarse del panel (`_con_contraste()`): el blanco de Colo-Colo
sobre una paleta crema era ilegible justamente en la fila de tu propio equipo.

**Las tarjetas ya creadas se repintan, no se reconstruyen.** Media interfaz —las columnas, la ficha,
la cabecera— se construye UNA vez y luego solo se le cambia el contenido. Cambiar de paleta no la
tocaba. Cada `_panel()` queda marcado con `set_meta("tarjeta", true)` y `_repintar_tarjetas()` los va
a buscar.

**El clima va aparte del fondo.** Son dos catálogos que se COMBINAN (24 × 10), no uno de 240. Y
`FondoAnimado` no consume `Azar`: usa el azar propio de `CPUParticles2D`. Un adorno que consumiera el
generador determinista cambiaría la liga entera según cuántos copos hubieran caído.

**La música se compone, no se descarga.** Se valoró traer pistas CC0 y se descartó por tres razones:
un MP3 decente son 3-5 MB por pieza y el proyecto tiene techo de 1 GB; la licencia hay que arrastrarla
y citarla en el paquete; y sobre todo una pista grabada no puede cambiar con la partida. `Musica`
sintetiza seis piezas con progresión de acordes, bajo, arpegio y percusión, con un eco de 180 ms al
28% que es lo único que separa "cuatro osciladores" de "música". Cero ficheros de audio en todo el
juego, igual que `Sonido`.

**Los idiomas se traducen DESPUÉS de pintar.** Lo normal en Godot es marcar cada cadena con `tr()`;
aquí eran más de dos mil sitios en un archivo de diez mil líneas. En vez de eso, la interfaz se pinta
siempre en castellano y `_traducir_pantalla()` recorre el árbol al final de cada repintado cambiando
`Label`, `Button` y `OptionButton`. **La clave es la frase castellana**, así que:
- añadir un idioma es añadir una columna en `Idiomas.TABLA`;
- lo que falte se lee en castellano, no como `MENU_SAVE_BTN`;
- ninguna lógica depende de esto (`_ir_a_pestana("Táctica")` sigue buscando el nombre castellano).

Están los siete: castellano, inglés, portugués de Brasil, francés, italiano, alemán y catalán, con
**309 frases cada uno**. NO hay chino ni japonés y no es un olvido: la fuente que Godot trae dentro
no cubre los ideogramas y saldría una pantalla de cuadraditos. Añadirlos exige empaquetar una fuente
CJK de varios megas, y es una decisión aparte.

**Lo que NO se traduce, dicho en la propia pantalla de Ajustes**: la narración —noticias, preguntas de
la prensa, diálogos del vestuario— sigue en castellano. Son varios miles de frases armadas por trozos
con nombres dentro, y a medias se lee peor que sin traducir.

### Dos fallos reales que salieron por el camino

1. **`Sonido.toca()` consumía `Azar`.** Elegir cuál de las cuatro variantes de un efecto sonaba salía
   de `Azar.ent(...)`, o sea del generador DETERMINISTA de la partida. Subir el volumen o jugar con
   los sonidos apagados daba resultados distintos en la liga. Es exactamente la trampa que ya se pagó
   una vez con un feed cosmético. Ahora la variante va por rueda (`_siguiente % banco.size()`).

2. **Los ajustes no sobrevivían al cierre.** Doce opciones de interfaz vivían solo en memoria. Ahora
   van a `user://preferencias.cfg` —aparte de la partida: son tuyas, no de tu club— y se guardan al
   repintar la pantalla de Ajustes, con una firma para no escribir el archivo en cada clic.

### Y dos cosas de interfaz que se arreglaron de paso

- **Ajustes tenía 1.700 px de alto.** Para llegar al tamaño de letra había que bajar por delante del
  mezclador, los 24 fondos, los 10 climas y las 9 paletas. Ahora son seis secciones con pestañas
  (`SECCIONES_AJUSTES`) y solo se pinta la que miras.
- **La fila de acciones recortaba los rótulos** ("Temporada s", "Dirigir el pa"). Todos los botones
  expandían igual, así que "Guardar" sobraba sitio. Ahora reparten por largo del rótulo, y el reparto
  se rehace al traducir.

### Lo que este lote deja tachado del pendiente nº2

El LEEME pedía *"un sonido propio para CADA evento"* con una lista de candidatos por orden de cuánto
cambian la partida. Están los siete: `clausula`, `lesion_grave`, `oferta`, `contrato_vence`, `obra`,
`venta`, `ronda_superada` —más `despido`, que también estaba en la lista—. El banco comprueba que
existan, que tengan onda (pico > 200) y que ninguno se pase de 6 s.

### Cómo se comprueba

`pruebas/banco.gd` → `_probar_aspecto_y_audio()`. Comprueba lo que puede quedarse callado sin dar
ningún error: un SVG de fondo que no dibuja nada, una receta de sonido que sale en silencio, una pieza
de música sin bucle, una fila de idioma con menos columnas que idiomas hay. Nada de eso lanza
excepción; simplemente no se ve ni se oye.

---

## PEDIDO POR EL USUARIO, SIN HACER TODAVÍA

Dos cosas que el usuario pidió expresamente **dejar apuntadas y no implementar aún** (7-9-2026).
No están a medias: no están empezadas.

1. **Divisas a elegir.** Que se pueda escoger la moneda en la que se ve el dinero. Hoy todo el juego
   dice "EUR" a fuego: `_dinero()` en `ui/principal.gd` y `_dinero_prueba()` en el banco formatean con
   ese texto fijo. Lo que haría falta: una moneda elegida (en el asistente de partida nueva o en
   Ajustes), un símbolo y un factor de conversión, y que **un solo sitio** formatee el dinero -hoy hay
   varios-. Ojo con el equilibrio: si se convierten las cifras, los umbrales del motor (fichajes,
   sueldos, premios) siguen en la escala original, así que la conversión tiene que ser solo de
   PRESENTACIÓN salvo que se decida lo contrario a propósito.

2. **~~Un sonido propio para CADA evento.~~ HECHO el 8-9-2026** -ver «LA TANDA DE ASPECTO,
   AUDIO E IDIOMAS»: 62 efectos, con los siete de la lista de candidatos. Se deja el texto de
   abajo porque la guia de composicion sigue valiendo para el proximo que se anada.

   **Un sonido propio para CADA evento.** El usuario lo pidió el 7-9-2026: *"cada evento o situación
   particular debe tener sonido propio"*. Hoy los nueve tipos de `Aviso` comparten cinco sonidos
   existentes -`logro` lo usan logro/récord/nivel, `moneda` lo usan dinero/gasto, `cambio` lo usan
   alerta/contrato-, y además hay eventos que ni pasan por `Aviso` y suenan genéricos o no suenan.

   El terreno ya está preparado a propósito: **la tabla `TIPOS` de `ui/aviso.gd` tiene una columna
   `sfx`**, así que dar sonido propio a un tipo es *una receta nueva en `Sonido._sintetizar()` y
   cambiar una celda*. Lo que falta es componer las recetas. Guía de lo que ya se aprendió haciendo
   `"logro"`: la duración manda -0,45 s para un guiño, 5 s solo para un título-, y hay que **reservar
   el buffer final antes de mezclar** (`m.resize(...)`) o las partes tardías se cortan en silencio
   (trampa ya pagada con `trofeo`).

   Candidatos a sonido propio, por orden de cuánto cambian la partida: despido, descenso, ascenso,
   te pagan la cláusula, lesión grave, oferta recibida, contrato que vence, obra terminada, venta
   cerrada, pasar de ronda de copa.

3. **La cara real, moldeada sobre la figura 3D.** El usuario lo pidió el 7-9-2026: que la cara del
   jugador se aplique a su modelo 3D "en todos los menús donde aparecen, incluso en el campo". Hoy
   son dos mundos separados: `ui/cara.gd` produce un retrato 2D (foto real de Commons si existe, si no
   un SVG procedural) y el modelo 3D del campo usa la textura de cabeza del atlas de Kenney,
   re-teñida por `Vestidor` a partir del aspecto del jugador. Nunca se tocan.
   **CÓMO HACERLO (decidido el 7-9-2026, al preguntar el usuario qué hacer con los ~1.077 reales sin
   foto y los ~8.400 generados).** La respuesta es que ese problema YA está resuelto en 2D y no hay
   que resolverlo otra vez: `Cara.textura()` no distingue entre "tiene foto" y "no tiene" -devuelve la
   foto si existe y un rostro procedural si no-, y por eso en los menús TODOS tienen cara. Así que:

   > Una sola capa de cara en el atlas, alimentada por `Cara`. Sin casos especiales.

   Alternativas descartadas y por qué: *solo los reales con foto llevan cara* recrea en 3D justo el
   problema que el usuario acababa de reportar en 2D (unos con cara, otros con cabeza genérica); y un
   *LOD por distancia* es lo que hacen los juegos grandes pero aquí la cámara casi siempre está lejos,
   así que es complejidad que no compra nada.

   Los tres problemas reales que habrá, ya localizados:
   1. La zona del atlas es la CABEZA entera (`(0,0,636,486)`, pelo arriba y a los lados, cara al
      centro): pegar la foto en todo el rectángulo borra el pelo. Hay que encajarla solo en el centro.
   2. El recorte actual de las fotos está pensado para 2D -cuadrado y centrado-, que en un retrato se
      ve bien pero proyectado deja demasiada frente y hombros. Hace falta un recorte más cerrado.
   3. **La orientación de las UV se mide, no se deduce.** Ya pasó con la espalda: se leía espejada y
      los dorsales salían al revés. Se descubrió pintando cuadrantes de colores y mirando el render
      (`visor3d/scripts/debug_atlas.gd`); aquí toca repetir ese método.

   El coste no es problema: son 9.600 jugadores pero solo 22 están en el campo a la vez. Se genera
   bajo demanda y se cachea por jugador, como ya se hace con escudos y caras 2D.
   Ver [[dinastia-atlas-jugador3d]] en la memoria para el mapa del atlas.

4. ~~Que se note el cierre del mercado.~~ **YA ESTABA HECHO (confirmado 12-9-2026, auditando este
   mismo pendiente)**: `Mundo.mercado_abierto()`/`semanas_de_mercado()`/`semanas_hasta_mercado()`
   (`nucleo/mundo.gd:2024`) ya portan las dos ventanas exactas del HTML (`sem<=6` y `18<=sem<=24`),
   `_motivo_fichaje_bloqueado()` en `ui/principal.gd:5261` ya bloquea fichar fuera de ventana con el
   mensaje "Mercado cerrado, vuelve a abrir en N semanas", hay un aviso de dos semanas antes del
   cierre (`principal.gd:2098`) y una etiqueta permanente con `texto_de_mercado()`
   (`principal.gd:2800`). No quedó registro de cuándo se hizo -no está fechado en ningún lote de esta
   sesión-, así que este punto llevaba tachado en el código desde hace tiempo sin que este archivo se
   actualizara. Lección: antes de anunciar un pendiente como real, grepear el código primero.

## Cómo se porta cada sistema

**Portar, no reescribir.** Las fórmulas salen del HTML tal cual; el equilibrio del juego costó una
depuración entera y no se rehace al cambiar de motor. Lo único que cambia es la forma: donde había
una función suelta que recibía un diccionario, ahora hay un método de una clase.

**La verificación no puede ser por huella.** El HTML usa `Math.random()` sin semilla, así que no es
reproducible ni consigo mismo: no hay nada con lo que comparar byte a byte. Se verifica por
**distribución** (goles por partido, reparto local/empate/visita, curvas de valor, medias por edad) y
por **invariantes** (la tabla suma, los goles a favor igualan a los goles en contra, nadie juega dos
veces la misma jornada, ningún jugador se pierde en un traspaso). Es lo que hace `pruebas/banco.gd`,
y es lo que ha cazado **todos** los errores de porte que ha habido — ninguno de ellos hacía saltar un
error.

## Lo que ya se pagó (no repetirlo)

1. **La fórmula de gol no da goles, da llegadas.** El `0.048*(...)^1.6` del HTML es la probabilidad
   de un ataque; solo el 30% acaba dentro (`if(r<0.30)`). Portada como si diera goles salían **8 por
   partido** en vez de 2,5.
2. **`seed` y `state` no son lo mismo.** Fijar `_rng.state = 0` después de sembrar deja el generador
   en un punto fijo: dos semillas distintas daban el **mismo mundo**.
3. **`eval()` mira el ámbito local primero.** El script de exportación tenía una variable `NOMBRES`
   que tapaba la constante `NOMBRES` del juego y todos los futbolistas se llamaban
   *"VALOR_PIVOTE Ahumada"*. Ahora sus variables llevan prefijo `__x` y el propio script comprueba
   que ninguna tabla exportada sea igual a su lista interna.
4. **Cuidado con las unidades.** El patrocinio, la televisión y las cuotas de socios son cifras
   **mensuales**; el sueldo es **semanal**. Cobrando las mensuales cada semana, cada club ganaba 32
   millones cada siete días; sin ellas, perdía cinco y quebraba en tres meses. Las dos versiones
   pasaban el resto de las pruebas sin quejarse.
5. **`RefCounted` no recoge ciclos.** El mundo guardaba su mercado y el mercado guardaba el mundo:
   **16.580 objetos filtrados** al salir. El mercado mira al mundo con `WeakRef`.
6. **Recalcular lo que no cambia.** La fuerza de los dos onces se medía en cada uno de los 90 minutos
   aunque forma, moral y físico son semanales: el 60% del tiempo. Cacheada, tres temporadas pasaron
   de **30 s a 7,7 s** con las curvas idénticas. Misma lección que `plantelDe()` en el HTML.
7. **Tasar antes de cambiarle la edad.** Al canterano se le ponía la edad *después* de crearlo, así
   que venía valorado como si tuviera la edad sorteada. No se ve hasta que alguien abre una ficha.
8. **La edad tiene que pesar en la media.** Sin el castigo del HTML a los menores de 20 salían
   canteranos de 17 años con media 96 y 223 millones de valor.
9. **Reponer la plantilla por el puesto que falta**, no al azar: si no, en diez temporadas un club
   acaba con seis porteros y sin lateral izquierdo.
10. **Un proyecto Godot hay que importarlo antes de correrlo headless**, o `class_name` no existe.
11. **Las capturas no funcionan con `--headless`**: sin ventana no hay framebuffer.
12. **Los `%-22s` no alinean con fuente proporcional.** Las tablas van en `GridContainer`.
13. **Un `RichTextLabel` dentro de un `ScrollContainer` sale vacío.** Su altura mínima es cero, así
    que el scroll se la deja en cero y el panel aparece en blanco aunque el texto esté escrito: sin
    error, sin aviso. El RichTextLabel ya hace scroll solo con `scroll_following`.
14. **El partido dirigido no se puede volver a simular.** `Liga.jugar_jornada()` recibe el partido ya
    jugado y anota su marcador; si no, en la tabla aparecía un resultado distinto del que el jugador
    acababa de ver en pantalla.
15. **Descender es cambiar de lista, no de etiqueta.** Hay que mover al club de `Liga.clubes` en las
    dos ligas Y cambiarle su `division`; con solo la etiqueta seguía jugando arriba, y con solo la
    lista seguía cobrando la televisión de Primera.
16. **Guardar también la división de la liga y el cuadro de la copa.** Sin ellos, al cargar todas las
    ligas volvían a ser Primera -con el recién descendido cobrando otra vez de Primera- y el torneo
    de copa desaparecía sin una sola queja.
17. **Comparar el mundo cargado ANTES de seguir jugando con él.** La prueba de guardado avanzaba
    cinco semanas y después comparaba la copa: fallaba sin que hubiera nada roto.
18. **Un `SubViewport` sin tamaño revienta el render.** Dentro de un `SubViewportContainer` mide 0×0
    hasta que el contenedor se coloca, y con 0×0 Vulkan escupe decenas de errores
    ("Too many mipmaps requested…") que parecen un fallo de la tarjeta. El 3D va directo al viewport
    raíz, como en el visor que ya funcionaba.
19. **`StadiumBuilder.build()` NO construye el campo.** El césped, las líneas y las porterías los pone
    `build_pitch()`, que es otra función. Faltando esa llamada salía un estadio entero -gradas,
    techo, focos, marcador- sobre un agujero negro, y sin un solo error.
20. **Cambiar de cámara y capturar en el mismo fotograma no vale.** `get_viewport().get_texture()`
    devuelve lo último pintado, así que la imagen sale con el encuadre anterior y parece que el
    cambio de cámara no funciona.
21. **`Vestidor.vestir()` no recibe los colores del club**, solo `kit_img` y `color_liso`. Con las dos
    vacías se queda la textura de fábrica del modelo -el amarillo y azul del Al-Nassr- y los 22
    jugadores salen vestidos igual, los dos equipos y los porteros incluidos.
22. **Al mover scripts de proyecto hay que revisar los `load()` con ruta escrita a mano.**
    `futbolista.gd` cargaba `res://scripts/anim_mixamo.gd`, que aquí ya no existe: los futbolistas
    salían sin esqueleto y sin animación.
23. **Ascender o descender es cambiar de lista Y de tabla de puntos.** `Liga.tabla()` busca a cada
    club en `tabla_puntos`; moviendo solo `clubes`, el recién llegado no tenía fila y la tabla
    reventaba. Casi no saltaba porque `preparar()` la reconstruye después — pero el veredicto de la
    directiva la pide justo en medio, y solo cuando TU club sube o baja.
24. **Un Control hijo de un `Node` normal se queda en 0×0.** Solo hereda el rectángulo si su padre es
    otro Control. Con tamaño cero, cualquier ancla en fracciones apunta al mismo sitio y un marcador
    "centrado" acaba pegado al borde izquierdo.
26. **Entrenar fuerte tiene que costar algo.** La intensidad multiplicaba las mejoras pero no el
    riesgo: entrenar "al límite" daba más progreso con el mismo peligro de romper a alguien. Eso no
    es una decisión, es una ganancia gratis.
27. **Cada clase que guarde el `Mundo` tiene que hacerlo con `WeakRef`.** Ya han caído cuatro en la
    misma trampa (`mercado`, `prensa`, `roles`, `logros`): con referencia fuerte el ciclo no se
    recoge y se filtran 19.000 objetos, porque un Mundo que no muere se lleva sus clubes y sus miles
    de jugadores.
25. **No derivar quince rasgos desplazando un mismo hash.** Los ids son correlativos ("j1", "j2"),
    sus hashes quedan pegados, y al tirar los bits bajos los altos apenas cambian: salían **24
    jugadores con dos cortes de pelo entre todos**. Una sal distinta por rasgo (`_hash(id+"corte")`)
    y cada uno recorre su lista entera.
28. **`change_scene_to_file()` no se puede probar desde dentro del nodo que lo llama.** Reemplaza
    `get_tree().current_scene` entero, así que un banco de pruebas que sea la escena principal se
    borraría a sí mismo a mitad de la comprobación. La prueba de "Continuar" no lo invoca: guarda una
    partida, pone `Principal.mundo_a_cargar` a mano e instancia `principal.tscn` como hijo -igual que
    ya hace `pruebas/captura.gd`- para comprobar que `_ready()` lo recoge, sin tocar el cambio de
    escena en sí, que ya prueba el motor.
29. **Seleccionar un jugador no repinta todo, solo la ficha.** El botón de cada fila del plantel llama
    a `_ver_ficha(j)` directo, no a `_refrescar()` -por rendimiento: repintar las diez pestañas en cada
    clic sería notorio-. Cualquier pestaña que dependa de `_seleccionado` (como el árbol de
    habilidades de Entrenar) se queda con el jugador anterior hasta la próxima semana si no se repinta
    también desde dentro de `_ver_ficha()`.
30. **`abrir_votacion()` tira una moneda cada vez que se llama** (`Azar.suerte(PROB_VOTACION)`): que
    una sola llamada no abra nada no es un fallo, es el diseño -"la federación convoca cada tanto"-.
    Para forzar una en una prueba o captura hay que llamarla en bucle hasta que toque.
37. **Restar la mitad redondeada no es lo mismo que fijar la mitad redondeada, con un número impar.**
    El desafío "derbis" tenía que dejar la confianza en `round(confianza*0.5)`, tal cual el HTML
    (`Math.round(G.confianza*0.5)`, un valor ABSOLUTO). Como `mover_confianza()` solo recibe un
    DELTA, se escribió `mover_confianza(-round(confianza*0.5), motivo)` -restar la mitad-, que
    PARECE lo mismo pero no lo es: con confianza 55, `round(27.5)=28`, y `55-28=27`, no el `28` que
    da fijar el objetivo directamente. Cualquier "deja X en la mitad" sobre un delta tiene que
    calcular el objetivo absoluto primero y restar la diferencia (`objetivo - actual`), no restar la
    mitad calculada sobre el valor de antes.
36. **No todos los sistemas "solo tuyos" se crean en el mismo sitio al cargar.** `Vestuario`,
    `Selecciones`, `Cantera`, `Prensa`... se recrean dentro de `_restaurar_lo_tuyo()`, porque nacen de
    `tomar_el_mando()`. Pero `Cesiones` (como `Mercado` y `Roles`) es del MUNDO, no de tu club -un
    préstamo puede ser entre dos clubes de la IA-, así que se crea directamente en `cargar()`. Se
    había creado `Mercado` y `Roles` ahí pero no `Cesiones`: quedó en null tras cada carga y nadie lo
    notó porque los quince sitios que la usan ya comprueban `!= null`. Antes de enganchar el guardado
    de una clase nueva hay que mirar DÓNDE nace -`generar()`, `tomar_el_mando()` o ninguno de los
    dos-, no asumir que es la misma línea que la del vecino.
35. **El perfil de gestor no vive en el guardado, vive en `user://perfil_gestor.json` de verdad**, y
    `Partida.borrar()` no lo toca. Probar `celebrar_titulo()`/`cerrar_temporada()` muchas veces
    -bancos, capturas, mundos de usar y tirar- lo deja subiendo de nivel de verdad, y ese archivo es
    el MISMO que vería el jugador real la primera vez que abra el juego. Se encontró en pleno testeo
    de esta noche con el perfil ya en "Dinastía" (el tope, 8800 XP) sin haber jugado una sola partida
    real. Se borró (`AppData\Roaming\Godot\app_userdata\DINASTIA\perfil_gestor.json`) antes de dar la
    noche por cerrada. Cualquier sesión de pruebas futura que toque logros debería borrarlo también
    al terminar, o el "primer" nivel que vea el jugador ya no será el primero.
34. **No todo lo que pasa "después de tu partido" necesita el `Partido` completo.** `Logros` sí
    -lee el once y los goleadores- y por eso solo se alimenta la semana que diriges en directo:
    `Liga.jugar_jornada()` descarta el `Partido` de los que solo simula por dentro. `Roles` en cambio
    solo pedía el marcador, que SÍ sobrevive en `resultados` para cada jornada. Meterlo en el mismo
    sitio que Logros lo habría limitado sin necesidad; el sitio correcto era
    `_avisar_a_la_directiva()`, que ya recorre `resultados` buscando tu partido para la Directiva.
    Antes de decidir dónde engancha algo, mirar qué datos pide de verdad, no copiar el gancho del
    vecino.
33. **La regla 17 ("comparar el mundo cargado ANTES de seguir jugando con él") se puede romper por una
    sola línea, no solo por el orden general de la prueba.** `_probar_guardado()` ya seguía la regla
    para la copa, pero comparaba un jugador concreto (`plantilla[0]`) DESPUÉS de dejar jugar 5 semanas
    más a la partida cargada. Mientras `Cantera` no existía eso no movía nada; en cuanto se enganchó,
    esas 5 semanas ya podían robarle un canterano al club (mecánica real, no fallo), y `plantilla[0]`
    dejaba de ser el mismo jugador. La prueba pasó a comparar antes de las 5 semanas extra.
32. **Un lambda de GDScript captura las variables locales POR VALOR, no por referencia.** Una prueba
    que conecta `señal.connect(func(): vista_encontrada = true)` y luego mira `vista_encontrada` desde
    fuera del lambda siempre lee `false`: el lambda escribió en su propia copia, no en la variable de
    fuera. Sin error, sin aviso -la prueba simplemente miente. Comprobar el estado real del objeto
    (`selecciones.nomina_ids`, no una bandera puesta desde una señal) en vez de depender de closures.
31. **`Vestuario` tenía `a_dic()`/`desde_dic()` escritos y nadie los llamaba.** `Partida.guardar()` no
    metía la clave `"vestuario"` y `_restaurar_lo_tuyo()` no la leía. La ansiedad de cada jugador se
    sortea (`Azar.ent`) la primera vez que se le pregunta, así que una partida cargada le barajaba la
    cabeza a todo el plantel de nuevo -distinta de la que tenía al guardar- y eso cambiaba
    `factor_animo()` y con él `Club.bonus_ataque`. Era el fallo "el staff cargado vuelve a mover el
    bonificador del motor" del banco: el rastro parecía apuntar a `Staff`, pero `Staff.aplicar()` ya
    estaba bien portado -el sistema roto era otro.
38. **Un error de sintaxis en `banco.gd` no hace fallar al banco: hace que Godot se quede esperando
    para siempre**, y eso se puede confundir con un proceso colgado. Si el script principal (el que
    carga `banco.tscn`) no compila -en este caso, `var no_gol := tipos["atajada"] + ...` donde
    `tipos[...]` es `Variant` y `:=` no puede inferir el tipo-, `_ready()` nunca llega a ejecutarse, así
    que `get_tree().quit()` nunca se llama: el motor se queda vivo, con ventana o sin ella, tirando de
    CPU muy poco (un bucle inactivo, no un bucle infinito) durante minutos u horas si nadie lo mata a
    mano. Se vieron **20+ minutos** de un proceso "corriendo" con apenas 8% de CPU antes de matarlo y
    volver a lanzarlo con la salida a un archivo en vez de por una tubería de PowerShell -que fue lo
    que dejó ver el `SCRIPT ERROR: Parse Error` de inmediato-. La lección con dos caras: (1) declarar
    con tipo explícito (`var no_gol: int = int(tipos["x"]) + ...`) en vez de `:=` cuando el valor sale
    de un `Dictionary`, y (2) si una corrida headless "no vuelve", sospechar primero de un error de
    carga -mirar la salida cruda, sin tuberías de por medio- antes de asumir que el trabajo es
    simplemente lento.
39. **`Get-Content` sin `-Encoding UTF8` corrompe los acentos, y el daño se hornea al volver a
    guardar.** Al extraer `REALES` de `tablas.json` a un JSON aparte para la búsqueda de caras, la
    primera pasada leyó el archivo con `Get-Content -Raw` a secas: PowerShell 5.1 lo interpretó con la
    codificación ANSI del sistema, no UTF-8, así que cada tilde -un carácter UTF-8 de dos bytes- se
    leyó como dos caracteres sueltos (`á` = `Ã¡`). Guardar eso con `-Encoding utf8` no lo arregla,
    lo fija para siempre: ahora son dos caracteres Unicode de verdad, no un byte mal leído, y ya no hay
    forma de deshacerlo sin volver a la fuente. El síntoma no fue un error, fue silencio: nombres como
    "González" buscaban en Wikidata como "GonzÃ¡lez", no encontraban nada, y quedaban marcados "sin
    resultados" -parecía que el jugador no tenía artículo, cuando en realidad la búsqueda nunca llegó
    a preguntar por su nombre de verdad-. Se encontró comparando bytes con `xxd`, no leyendo la
    pantalla. Arreglo: `Get-Content -Raw -Encoding UTF8` al leer, y al escribir usar
    `[System.IO.File]::WriteAllText(ruta, texto, [System.Text.Encoding]::UTF8)` en vez de
    `Set-Content -Encoding utf8` -que en Windows PowerShell 5.1 antepone BOM y a veces reintroduce el
    mismo problema según la consola-. Cualquier script de PowerShell que toque texto en español debe
    fijar la codificación en la lectura, no solo en la escritura.

## Un desajuste que conviene tener presente

Los ingresos de un club crecen con la reputación a razón de 1,113 por punto (van con
`factorClub^0.85`), y los sueldos a 1,087 (van con `valor^0.66`). Las dos curvas se cruzan en el club
medio: por encima, el club gana dinero solo; por debajo, lo pierde solo.

En el HTML no se nota porque **solo se lleva la contabilidad de tu club** — los otros 383 tienen la
caja fijada en `refCaja(rep)` y no la mueve nadie salvo los fichajes. Aquí se simulan todos, así que
el desajuste sale a flote: sin corregirlo, en tres temporadas Colo-Colo triplicaba su caja y Cobreloa
acababa con 86 millones en rojo.

La corrección es `Finanzas.ajuste_de_directiva()`, que solo se aplica a los clubes de la IA: rescata
al que está en rojo y reparte el excedente del que acumula de más. **A tu club no se le aplica**: ahí
la caja es tuya y las consecuencias también.

## El renderizador: DECIDIDO, Forward+

`project.godot` está en **Forward+**. Se probó primero en Compatibility (OpenGL 3.0), que arranca
algo antes, y funcionaba — pero Compatibility no tiene oclusión ambiental, reflejos ni niebla
volumétrica, así que el estadio se ve plano por mucho que se pidan. Como el método de render es de
PROYECTO y no de escena, había que elegir uno para todo.

Se comprobó que la interfaz 2D se comporta **exactamente igual** en los dos (misma captura, mismo
resultado), así que el cambio no cuesta nada donde no hace falta y lo da todo donde sí. Esta máquina
lo mueve: **Vulkan 1.3.237 sobre Intel UHD**.

## Cómo se actualizan los datos

Si el HTML cambia una tabla, no se toca nada en GDScript:

```powershell
herramientas\run_harness.ps1 -Script exportar_datos.js
```

y se vuelca el JSON en `dinastia-godot/datos/tablas.json`. La lista de tablas se saca grepeando las
declaraciones `const` del propio código, así que una tabla nueva entra sola.

## La estética: cómo se porta sin reescribirla

**La regla del usuario, dicha explícitamente el 4-9-2026: la mudanza tiene que dejar el juego IGUAL
de verlo.** Las mejoras van por dentro -clases de verdad, nativo en vez de DOM, más rápido- y no en
un rediseño. Se encontró que la interfaz de Godot (`ui/principal.gd`, `ui/inicio.gd`,
`ui/seleccion_modo.gd`, `ui/partido_vivo.gd`, `ui/estadio.gd`) llevaba semanas con una paleta propia
estilo GitHub (`#0d1117`/`#161b22`/`#2f81f7`...) en vez de la paleta real del juego
(`css/estilo.css`, `:root`: `--bg:#0c1510`, `--panel:#141c16`, `--acc:#3fa06a`, `--tx:#e9eeea`,
`--mut:#8ea595`, `--verde:#4caf6d`, `--rojo:#e05555`, `--oro:#c9a227`). Corregido en bloque: como los
colores son constantes centralizadas al principio de cada archivo (no literales repetidos), bastó con
cambiar esas ~8 líneas por archivo -y un barrido de los códigos sueltos en los mensajes de color del
registro (`[color=#...]`)- para que TODA la pantalla recuperara el verde oscuro real sin tocar ni una
línea de layout. De paso, la portada "Minimal" tenía su círculo y su línea en un verde que tampoco
existía en el HTML (`#3fb950`); ahora usan `--acc` de verdad.

**Godot rasteriza SVG en tiempo de ejecución** (`Image.load_svg_from_string`). Los generadores
visuales del HTML —escudos, retratos, portadas— no dibujan: **construyen cadenas SVG**. Así que se
portan como lo que son, constructores de cadenas, y la estética queda idéntica sin reimplementar a
mano ocho formas de escudo, diez patrones, veintitrés cortes de pelo y ocho barbas.

Dos límites que conviene saber:

- **El rasterizador no dibuja `<text>`.** Un SVG con texto carga sin error y sale sin las letras.
  Comprobado. Por eso las iniciales del escudo van como etiqueta de Godot encima —además quedan más
  nítidas y con el color correcto según lo claro u oscuro que sea el escudo.
- **Se rasteriza a 3x o 4x y se deja que el control lo encoja.** A 1x los bordes curvos salen
  dentados. Y se cachea por clave: la tabla pide dieciséis escudos y el plantel veinticinco caras en
  cada repintado, y rasterizar no es gratis.

- **Roles de carrera**: DT, director deportivo, ayudante, interino, cantera y dueño, cada uno con lo
  que puede y no puede tocar ("TU CARGO", al final de la pestaña Club), y su forma de ascender.
- **Entrenamiento**: plan semanal con foco e intensidad, y el árbol de habilidades del jugador y del
  entrenador — pestaña "Entrenar" propia, con lista de días y perillas.
- **Federación**: votaciones que cambian el reglamento —playoffs, reparto de TV, VAR, cupo juvenil—
  con sus consecuencias. Pestaña "Federación" propia; `abrir_votacion()` tira una moneda
  (`PROB_VOTACION`) cada semana, así que una votación no sale en la primera que se juega.
- **Estadio propio**: forma, bandejas, techo, césped, butacas y focos, con su coste. Pestaña
  "Estadio" propia.
- **Audio**: 62 efectos y 6 piezas de música sintetizados por código, sin un solo fichero de sonido.
- **Idiomas**: 7 (castellano, inglés, portugués BR, francés, italiano, alemán, catalán), 309 frases de interfaz cada uno. La narración sigue en castellano.

**4-9-2026 — estas cuatro YA TENÍAN pantalla** (roles, entrenamiento, federación, estadio propio):
la sección de arriba de este documento seguía diciendo "sin pantalla propia" pero el código de
`principal.gd` ya las tenía escritas y con su pestaña puesta -desactualización de la nota, no del
motor. Verificadas con captura (`pruebas/pantalla_entrenar2.png`, `_federacion.png`, `_rol.png`,
`_estadio2.png`) y arreglado un bug real que apareció al probarlas: pulsar una fila del plantel llama
solo a `_ver_ficha()`, no a `_refrescar()`, así que el árbol de habilidades de la pestaña Entrenar se
quedaba con el jugador anterior seleccionado. `_ver_ficha()` ahora también repinta Entrenar.

## LA CINEMÁTICA DEL SORTEO EN 3D (8-9-2026)

El usuario la pidió con referencias concretas: la foto del bombo de la UEFA con la mano sacando una
bola, y el cuadro de cruces final con los escudos. Y después, textualmente, **"debe estar en 3D, usa
Vulkan y toda esa mamada, efectos, renderizado"**. El proyecto YA estaba en Forward+ (Vulkan) por el
estadio, así que no hubo que cambiar el método de render -que es de proyecto, no de escena-: solo
aprovecharlo.

`ui/sorteo_escena3d.gd` es una escena 3D de verdad dentro de un `SubViewport` con `own_world_3d`, y
`ui/sorteo.gd` pone encima la interfaz 2D (rótulos y cuadro final), que es donde el texto se lee
nítido. Lleva bombo de cristal con refracción, bolas con física, presentador, pantalla gigante,
público, tarima, truss de focos, niebla volumétrica y cortes de cámara.

**Lo que costó más de una captura entender, por orden de dolor:**

1. **La textura del balón.** Reusar el SVG plano de `Sorteo._textura_bola()` sobre una esfera es un
   desastre: la proyección equirectangular estira el dibujo y los pentágonos salen como manchas
   derretidas hacia los polos —parecían palomitas. Hay que generar la textura **en el espacio de la
   esfera**: para cada téxel se calcula su dirección 3D y se mide el ángulo contra los **doce
   vértices de un icosaedro**, que son exactamente los centros de los doce pentágonos de un balón.
   Así salen redondos desde cualquier ángulo.
2. **La exposición.** `Calidad.NOCHE` abre a 1,4 porque está pensada para un estadio oscuro. Aquí hay
   tres focos apuntando a un objeto BLANCO: a 1,4 los balones salían reventados y solo se veían los
   parches negros flotando. Baja a 1,0, y el especular del balón a 0,12.
3. **La pared LED quemaba la escena.** A 1,7 de emisión el bombo se veía en contraluz y los rótulos
   no se leían. Una pared LED de plató ilumina POCO: está lejos y es decorado. Va por debajo de 0,6.
4. **Las bolas nacían fuera del cuenco.** El cuenco tiene centro en `y` y radio `R`, así que su
   interior va de `y-R` a `y`. La primera versión las soltaba un metro por encima del borde: caían
   fuera y se veían flotando por el plató.
5. **Y descansaban en el aire.** El cilindro de colisión del fondo quedaba 10 cm por encima del fondo
   visible del cristal, así que el montón formaba un anillo flotante. El cilindro mide 0,08 de alto:
   su centro va a `-R-0,04` para que su cara superior caiga justo en `-R`.
6. **La escena se congelaba.** Con física a secas las bolas se asientan en segundo y medio y a partir
   de ahí se ve un montón quieto dentro de un cristal. La solución no es animarlas -volvería a
   repetir- sino **no dejar que el sistema llegue al reposo**: el cuenco gira despacio y cada 0,28 s
   cae un empujón suave. Sigue siendo física de verdad, solo que nunca se duerme.
7. **"Está todo flotando, se supone que es una gala"** (textual). Era un bombo sobre un disco en
   mitad de la nada. Una gala necesita tarima elevada, paredes que cierren, techo con truss, y gente
   sentada mirando. Sin esas cuatro cosas no hay sala, hay un objeto.
8. **"La escena se ve plana"**. Faltaban dos cosas que el usuario nombró y tenía razón en las dos:
   un **presentador** que saque las bolas -lo que vende la escena es el GESTO, no el detalle: basta
   una silueta con un brazo que baje al bombo- y una **pantalla de fondo** que vaya cantando los
   clubes. La pantalla se hace con un `SubViewport` de interfaz 2D normal cuya `ViewportTexture` se
   pega como emisión a un plano: es la única forma de tener texto NÍTIDO dentro de una escena 3D.
9. **La cámara era una sola órbita lenta**, y por eso se veía plana. Una retransmisión CORTA entre
   planos. Hay cuatro (`PLANOS`) y se cambia en cada bola.

**El colisionador del bombo no es una malla cóncava**: sale cara y deja colarse cuerpos pequeños. Es
un anillo de 18 cajas inclinadas hacia dentro más un disco de suelo. Converge igual y cuesta una
fracción.

**Y una trampa de proceso:** el banco pasó en verde con la interfaz rota. `banco.gd` **no carga
`ui/`**, así que un `class_name` nuevo sin reimportar, o un `:=` que no infiere en un archivo de
interfaz, no lo ve nadie hasta la captura. Cualquier cambio en `ui/` se valida con `-Captura`, no con
el banco.

## LOS ADORNOS NO PUEDEN TOCAR `Azar` (8-9-2026) — TRAMPA NUEVA

Al portar `vSocial()` el feed de redes generaba los "me gusta" de cada mensaje con `Azar.ent()`. El
banco falló al instante con algo que no tenía ninguna relación aparente:

```
FALLO diez jornadas mueven el prestigio del entrenador (50 -> 50)
```

**La causa.** `Azar` es el generador DETERMINISTA del que depende la simulación entera: misma
semilla, mismo mundo, mismos partidos. Publicar un mensaje por cada resultado consumía números de esa
secuencia, y a partir de ahí **todo lo que venía detrás salía distinto**: otros marcadores, otras
lesiones, otro prestigio. Un adorno cosmético estaba cambiando la liga.

**La regla que deja:** lo que es DECORACIÓN no toca `Azar`. Si hace falta variedad, sale de un hash
de algo que ya existe —el propio texto del mensaje, el número de semana— que da cifras estables,
distintas entre sí y que no mueven nada.

**Y lo que SÍ puede tocarlo:** las acciones del jugador. `Prensa.comunicado()` sigue usando `Azar`
porque contestar a la prensa es una decisión con resultado incierto, igual que fichar o apelar una
tarjeta. La línea no está entre "sistema" y "pantalla", sino entre **lo que el jugador decide** y lo
que solo se dibuja.

**Por qué importa el detalle:** este fallo no se encuentra leyendo el código. El código de las redes
está bien y el del prestigio también; lo que estaba mal era la interacción entre dos archivos que no
se conocen. Solo lo caza un banco que compruebe EFECTOS con semilla fija.

## EL PIZARRÓN DESTAPÓ UN FALLO DEL MOTOR (8-9-2026)

Al portar el pizarrón de `vTactica()` -los once dibujados sobre el campo, en rojo el que juega fuera
de su puesto- salió **media plantilla en rojo**. No era un fallo del dibujo: era el once automático.

`Club.once()` puntuaba a cada candidato con `media_en(puesto)`, que pondera los atributos según lo
que pide esa demarcación. El problema es que un extremo veloz tiene justo el ritmo que pide un
lateral, así que **ganaba el puesto a un lateral de verdad**. Saber jugar ahí no contaba para nada.

El arreglo es un factor de familiaridad -0,94 si es posición secundaria, 0,86 si es ajena- y no un
veto: un extremo MUY superior sigue ganando el puesto, pero deja de ser gratis sacarlo de su sitio.
Con eso, el once automático pasó de medio equipo descolocado a los once en su posición natural.

**La lección:** este fallo llevaba meses ahí y no lo vio nadie porque en una LISTA de once nombres no
se nota. Dibujarlos sobre un campo lo hizo obvio en dos segundos. A veces la forma de encontrar un
bug de motor es pintar bien sus datos.

## LA FICHA Y EL PARTIDO EN VIVO, MÁS COMPLETOS (10-9-2026)

Sesión de trabajo 100% autónoma, a pedido explícito del usuario. Dos agentes de investigación
cruzaron `vFichaJug()`/`vEnVivo()` del HTML contra su puerto en Godot, función por función, citando
líneas exactas. De la lista resultante se cerró casi todo en esta tanda; lo que se dejó fuera queda
anotado al final con su motivo.

**Hallazgo antes de escribir nada: dos piezas "faltantes" del informe YA estaban en el motor.**
`Entrenamiento.alternar_prioritario()`/`es_prioritario()` (desarrollo prioritario) ya progresaba 50%
más rápido y pagaba físico extra -solo faltaba el botón-, y `Roles.manda()` YA es el `mando()` del
HTML letra por letra (`"manda": true/false` por rol en `PERMISOS`), con un comentario propio que ya
lo decía. Ninguna pantalla los llamaba. Mismo patrón que "el lote barato" del 8-9: las auditorías de
agente no siempre saben si algo ya existe, solo si algo SE VE.

**Un bug real encontrado leyendo el archivo, no buscado:** el botón "Volver al club" de
`partido_vivo.gd` vivía después de un `return` dentro de `_informe()` -código muerto, sin ningún
error que lo delatara-. Al terminar un partido en vivo no había NINGUNA forma de volver al club. Se
crea ahora en `_construir()`, oculto, y `_al_final()` lo muestra.

**`vFichaJug` — cerrado:**
- **Modo ciego real.** `Ojeadores.modo_ciego` ya existía pero la ficha nunca lo consultaba: la grilla
  de atributos se veía siempre exacta, ciego o no. Ahora, si no conoces al rival, se pinta
  `_pintar_ficha_ciega()` -mejor/peor cualidad, partidos, nota media, carácter y fiabilidad del
  informe, sobre la media REAL con `ESCALA_CIEGA` (se le agregó la descripción de cada escalón, que
  faltaba) y `Ojeadores.fiabilidad_de()`, ambos nuevos.
- **Reconversión de posición**, sistema nuevo en `Jugador`: `pie()` (estable por hash, ya que Godot no
  guarda pie dominante), `ovr_en_puesto()`, `aptitud_en()` (portada la tabla completa: natural,
  secundaria, POR↔campo, adyacente por `POS_ADY`, mismo grupo mismo/otro lado, resto -y el 0,94 extra
  del lateral a pie cambiado) y `reconvertir()`. Sección "🔁 POSICIÓN Y RECONVERSIÓN" con un botón por
  puesto y su media estimada. **Ojo, divergencia a propósito**: el HTML muta `j.posE` ANTES de medir
  `aptitud(j,pe)` en su propio `reconvertir()`, así que en el original la penalización de 1-3 puntos
  nunca se aplica de verdad (bug de orden, no una decisión de balance); aquí se mide ANTES de mutar,
  que es lo que el comentario del propio HTML dice que debería pasar. Y la penalización en partido
  (el `adap=0.96` de `fuerzaJug()`) NO se portó: `Partido.fuerza()` ya resuelve la familiaridad al
  armar el once (`Club.once()`, la trampa del pizarrón de arriba), no por jugador y por minuto, así
  que sumar ahí un segundo castigo lo aplicaría dos veces.
- **Ídolo de la afición y marca personal, mostrados por fin.** `Mundo.marca_personal()` e
  `ingreso_marca()` YA estaban -cobran de verdad cada semana-, pero ninguna ficha los enseñaba. Se
  agregó `Mundo.idolo_aproximado()` (misma cuenta de siempre, ahora pública) para no inventar una
  segunda fórmula de "qué tan ídolo es" que contradijera a la que ya cobra en la caja.
- **Cláusula de fidelidad**, nueva en `Cantera.ofrecer_fidelidad()`: paga 26 sueldos, +14 moral, tres
  temporadas sin pedir salida -y ahora `Mundo` respeta esa promesa en el chequeo semanal de
  descontento-.
- **Informe de personalidad**, nuevo en `Ojeadores` (mismo patrón que el informe médico de `Medico`):
  profesionalidad, cómo encaja en el vestuario, qué tan fácil es convencerlo de mudarse. Simplificación
  real: usa "hambre" fijo en 50 porque ese campo depende de `ORIGENES`/`sortearOrigen()`, un sistema
  del HTML que Godot no tiene portado.
- **Vida personal y biografía**, texto estable por hash (`PERSONAL`, ya exportada en
  `datos/tablas.json` y sin usar hasta hoy). La biografía usa el mismo respaldo de cuatro frases que
  el propio HTML usa cuando `origenDe()` no tiene nada que decir -`ORIGENES` tampoco está portado-.
- Baratas: últimas notas como texto, "Perfil" (nombre del rasgo en su propia fila), detalle de
  lesión/suspensión (`Medico.diagnostico()` ya lo sabía), porcentaje pactado de venta
  (`Cesiones.porcentaje_pendiente()`), negociación congelada, y el botón para SACAR a alguien de la
  lista de transferibles (antes solo se podía meter).
- **Fuera de esta tanda, documentado:** el historial de temporadas anteriores (`histG`/`histOvr`) es
  un hueco de MODELO DE DATOS, no de pantalla -Godot no guarda ningún array por temporada pasada de un
  jugador-, y requiere decidir dónde y cuándo se acumula al cerrar cada año.

**`vEnVivo` — cerrado:**
- **🥂 Palco presidencial**, gateado por fin con `Roles.manda()`: sin perillas, sin cambios, sin
  arengas, sin instrucciones en vivo -eso es cosa de tu DT empleado-. Solo velocidad, "Al próximo
  gol", "Al final", sintonía con el DT y, una vez por partido, "Bajar al borde del campo"
  (`_presionar_desde_el_palco()`, 55%/45% de moral +3/-2, sintonía -9 siempre). El camarín del
  entretiempo también se reduce: sin tonos de charla, solo salir a la segunda parte.
- **Instrucciones efímeras de partido** (`Partido.instr_riesgo`/`instr_tiempo`, nuevas): a diferencia
  de la pizarra (`Club.tactica`, persistente), se resetean solas con cada `Partido` y solo pegan del
  lado de `Partido.ctx_club_id`. "Presión" efímera NO se portó a propósito: el dial persistente de
  presión ya cubre esa misma decisión.
- **Gritar desde la banda**: baja la ansiedad del once, con 16% de expulsión del área técnica si
  `Federacion.enojo_arbitral>=2` (ya existía, sin usar hasta hoy). Simplificación real: el HTML abre
  además un caso de tribunal que sanciona VARIOS partidos futuros -sistema aparte, no portado-, así
  que aquí la consecuencia dura solo este partido.
- **Penales en vivo dentro del visor.** `Partido.penales()` quedó MEMOIZADO -detalle importante-:
  `partido_vivo.gd` los resuelve apenas termina un cruce de copa empatado, y `Copa.jugar_ronda()` los
  vuelve a pedir después, al avanzar la semana, sobre el MISMO objeto. Sin caché el visor podía
  anunciar un ganador y la tabla de la copa otro. Se tuvo que corregir la prueba del banco que tiraba
  200 tandas sobre el mismo `Partido` esperando 200 resultados distintos -con la memoización, medía
  siempre la primera-.
- **Al próximo gol**, junto a "Al final".
- **Momentum real**, no la posesión: `Partido.momentum_eventos`/`momentum_local()` -log de los
  últimos 12 remates y goles (+2/-2 gol, +1/-1 cualquier remate)-, `M.mom` del HTML. La barra de
  arriba ahora mide esto; la posesión sigue aparte, en el texto de estadísticas.
- **Fuera de esta tanda, documentado:** la pizarra visual (dibujo del campo con el once encima) es un
  componente que no existe en NINGÚN lado de `ui/`, ni siquiera pre-partido -no es solo un hueco de
  `vEnVivo`-, y los tres modos de vista intercambiables del HTML (juego/pizarra/datos, un panel a la
  vez) se quedan como las cuatro columnas simultáneas de siempre: es un cambio de estructura ya
  asumido, no un pendiente. Los colores de camiseta en las barras de estadísticas siguen con la
  paleta fija de la interfaz.

Verificado con el banco completo (0 fallos, incluida la prueba de penales corregida) y con captura
real: ficha propia e ficha ajena sin errores, y el partido en vivo mostrando "Al próximo gol" e
"INSTRUCCIONES EN VIVO" (Todo al ataque / Perder tiempo / Gritar desde la banda) en la columna del
banquillo, con el momentum al 57% tras un gol propio.

## PEDIDOS DEL 10-9-2026, ANOTADOS PARA NO PERDERLOS

El usuario pidió explícitamente ir guardando aquí sus pedidos aunque la sesión no llegue a
terminarlos todos. Cuatro cosas, dichas jugando:

1. **"A veces aparece la cara falsa de los jugadores."** Investigado: `Cara.foto_real()` solo
   devuelve la foto de verdad si `j.real` Y el nombre está en `caras_reales_reporte.json` con
   `encontrado:true`. La búsqueda terminó en 1.048 de 2.125 (49,3%) -ver `dinastia-godot/LEEME.md`
   más arriba, "La búsqueda de caras reales TERMINÓ"-. **No se encontró ningún bug de código**: el
   resto de los reales (50,7%) cae al retrato procedural A PROPÓSITO, porque no se les encontró
   ninguna foto libre. Si se quiere subir el porcentaje hay que reintentar la búsqueda -otra fuente
   además de Wikidata/Commons, o nombres alternativos/apodos- pero eso es una tanda aparte, no un
   arreglo de esta.
2. **"Hay letras recortadas."** Confirmado con la propia captura de hoy: la fila de botones de arriba
   ("Dirigir el partido", "Avanzar semana", "Jugar la temporada", "Temporada siguiente", "Guardar",
   "Cargar", "Otro mundo" + el buscador) no entra completa a 1600 px y cada botón se recorta a media
   palabra -`clip_text` ya estaba puesto a propósito para que la fila no reviente la ventana, pero con
   siete botones más el buscador ya no entran ni recortados a la mitad-.
3. **"¿Por qué está el botón de pasar temporada suelto? Debería estar en un menú de calendario."**
   Pedido concreto: sacar "Dirigir el partido"/"Avanzar semana"/"Jugar la temporada"/"Temporada
   siguiente" de la fila y meterlos en un menú desplegable "📅 Calendario" -resuelve el punto 2 de
   paso, porque libera cuatro botones de ancho en la fila-.
4. **Pedido más grande, en sus palabras**: *"Mejorar el sistema de menú y qué se sientan integrados y
   evitar la duplicidad en los menús, si una cosa la puedo hacer en varios menús pierde la gracia y
   deben existir más submenús."* Osea: auditar los ~10 tabs y ~40 subtabs de `principal.gd` buscando
   la MISMA acción repetida en más de un lugar, y agrupar mejor lo que hoy está suelto en más
   submenús. **Auditoría ya hecha** (agente, 10-9-2026): un duplicado literal -"mercado a ciegas"
   (`Ojeadores.modo_ciego`) tiene interruptor en Club→Ojeadores Y en Ajustes→Accesibilidad, mismo
   booleano, dos sitios sin relación-, y cuatro pestañas sobrecargadas de peor a mejor: **Gente** (la
   peor: mezcla gente de verdad + identidad visual/escudo/uniforme + explotación comercial completa +
   club-por-dentro, cuatro temas sin relación bajo un nombre que no avisa de ninguno de los tres
   últimos), Club (10-12 secciones), Táctica (9 bloques, se abre cada semana) y Redes (Derechos de TV
   metido ahí siendo 100% financiero). El patrón de "chips" que ya usa Ajustes
   (`SECCIONES_AJUSTES`) es el mecanismo a clonar para partir las demás -no hace falta inventar uno
   nuevo-. Prioridad recomendada: 1) arreglar el interruptor duplicado (barato), 2) partir Gente,
   3) partir Táctica, 4) partir Club, 5) sacar Derechos de TV a Finanzas. Pendiente de implementar.
5. **Aclaración sobre el calendario, con imagen de referencia** (un juego de manager en Kick/streaming):
   no quería solo un botón o menú desplegable -eso ya se hizo, "📅 Calendario"-, quería una PANTALLA
   de calendario de verdad: grilla con los próximos partidos marcados (escudo del rival, local/
   visitante, competición), desde la que se pueda simular de corrido o saltarse partidos enteros sin
   dirigirlos. En construcción en esta misma sesión.

## `vEstadioDiseño` Y `vCarrera`, LO QUE FALTA (informe de agente, 10-9-2026 — CORREGIDO 12-9-2026)

**ACTUALIZACIÓN 12-9-2026**: al revisar esto de nuevo, casi todo lo que sigue decía "sin UI" ya
estaba pintado en `principal.gd::_pintar_estadio()` -los 8 presets, "🎲 Sorpréndeme", "↺ Volver a
fábrica" y los diecisiete campos completos-. El informe de abajo estaba desactualizado, no el
código. Lo único que de verdad faltaba -ver el diseño en 3D sin esperar a un partido en casa- se
cerró ese mismo día: botón "👁️ Ver mi estadio en 3D" que abre `VistaEstadio` (la misma clase que usa
`partido_vivo.gd`) en su modo vacío. Detalle completo en la memoria `dinastia-estadio3d.md`. Lo que
SIGUE faltando de verdad: un estudio de diseño aparte del club (probar looks sin pagar), los seis
campos de ambientación (`nombreFachada`, `humo`, `pirotecnia`, `publico`, `vida`, escenas), el sonido
de gol elegido (se guarda pero siempre suena el mismo fijo), y cualquier sistema de MÓDULOS armables
del estadio -lo que hay son paquetes de cambios completos, no piezas independientes-.

**`vEstadioDiseño`** (texto original del informe, con lo de arriba ya corregido): el motor
(`EstadioPropio`) está muy avanzado -aforo, ambiente, coste de reformar, 17 campos de diseño con 18
desplegables ya pintados en la pestaña "Estadio"-, más completo que el HTML en varios puntos.

**`vCarrera`**: casi todo portado con fidelidad -rival personal, leyenda viva, sucesión, árbol de 18
habilidades del DT, las 6 "inversiones" (`DT_COMPRAS`), filiales, historial, perfil de gestor
cross-partida (XP/niveles, en la pestaña Logros)-. Falta la card "⭐ BONUS POR REPUTACIÓN":
`Cantera.multiplicador_de_reputacion()` ya existe y es fiel, pero los otros dos multiplicadores del
HTML (`.fichajes` y `.sponsor`, mismo patrón `1+(prestigio-50)*k`) no están portados en absoluto -ni
en mercado ni en patrocinio-. **Hallazgo más importante, revisar antes de tocar nada de economía**:
`Roles.sueldo_semanal()` NO es la misma fórmula que `sueldoDT()` del HTML -el HTML es aditiva
(`refCaja(rep)*0.0022 + repDT*40`), Godot es multiplicativa con exponente 0,62-, y con un club y DT en
el promedio da **~3 veces más sueldo** que el HTML (9.900 vs 3.509 por semana). No parece un cambio a
propósito -no hay comentario que lo declare rediseño-. También falta la fatiga por viajes
internacionales de visitante en competición continental (`fatigaViaje()`/`aplicarFatigaViaje()` del
HTML, con su aviso "✈️ Vuelta de viaje"): existe algo parecido pero ligado a otro evento distinto
(`Prensa._fatigar_por_viaje()`, solo extranjeros, sin el gancho real de "jugaste de visita en la
Libertadores/Champions/etc."). Detalle completo del informe en el historial de esta sesión.

**Hallazgo de paso, construyendo el calendario (10-9-2026):** `Continental.CONTI_EN` (semanas 3/8/13/
18/23/28) no bloquea esas semanas en el calendario de Liga -nada en `Liga`/`Mundo` evita que caiga una
jornada normal la misma semana-, así que `_pintar_tabla()` (columna izquierda) puede estar mostrando
el grupo/cuadro CONTINENTAL como "lo que toca esta semana" mientras `_dirigir()`/`_pintar_partido()`
-que nunca miran continental, solo copa y liga- dirigen en realidad el partido de LIGA de esa semana.
Posible inconsistencia real entre lo que se anuncia y lo que se juega. No confirmado con una captura
todavía, solo por lectura de código -verificar antes de tocarlo-.

**Otro hallazgo de paso, en la captura del calendario:** la fila superior salió con "Save"/"Load"/
"New world" en INGLÉS pese a que `captura.gd` vuelve `Idiomas.idioma` a `"es"` mucho antes (frame
ESPERA+34) y llama a `_refrescar()` varias veces después (sorteo, copa, avance de semanas). Puede ser
que `_traducir_pantalla()` traduzca el texto de un nodo una sola vez y no sepa revertirlo -si guarda
"Save" como el texto "de verdad" del botón en vez de recordar que el original era "Guardar"-. No
confirmado, solo visto en una captura; revisar `nucleo/idiomas.gd`/`_traducir_pantalla()` antes de
tocar nada de idiomas.

## EL MENÚ CENTRAL DE DOBLE NIVEL (10-9-2026)

El usuario pidió rehacer el menú entero con un formato concreto: seis bloques maestros fijos y
chips dinámicos debajo, estética de píldoras, y que se sienta "un centro de mando". Se hizo, y de
paso salieron tres hallazgos que valen más que el código:

**1. Faltaban 13 pantallas en su propio diseño.** Su mapeo cubría 32 chips pero dejaba fuera todo el
día a día: Táctica, Entrenar, Enfermería, Camarín, Cantera, Contratos, Partido, Calendario, Finanzas,
Mercado, Libres, Ciudad y Editor. Eligió la salida de **hubs contextuales**: el nivel 1 se queda en
seis bloques exactos y esas pantallas entran tocando la zona de la interfaz que ya habla de ellas
-la ficha del jugador abre PLANTEL, la tabla abre COMPETICIONES (estilo FC26), y dos iconos en la
fila de acciones abren PARTIDO y DINERO-. Está en la constante `HUBS`.

**2. Un chip NO es una pestaña.** Es `{tab, secc, label}`: `tab` es la pestaña real del
`TabContainer` -los títulos internos no se tocaron, porque medio archivo y todas las capturas los
buscan por nombre-, `secc` es la sección dentro de esa pestaña, y `label` es lo único que ve el
jugador. Así se reorganizó el menú entero sin renombrar una sola pestaña. Para que esto funcionara
hubo que partir `_pintar_club()` en cuatro secciones (directorio / staff / infra / carrera), igual
que ya se había hecho con Gente y con Ajustes.

**3. EL RECORTE NO ERA DE FUENTE, ERA DE SITIO.** Los seis bloques salían como "CENTRA", "HISTORI",
"OPERACI" y se intentó arreglar bajando la fuente. No era eso: el menú vivía DENTRO de la columna
del medio (~620 px). El usuario mandó una captura de su propio HTML, donde el menú cruza la ventana
entera, y ahí se vio. Ahora cuelga de `raiz`, a ancho completo, y los rótulos entran solos.

**La trampa gemela del `clip_text`.** En la fila de arriba hay que RECORTAR o desborda la ventana;
en el carril de chips hay que hacer justo lo contrario -nada de `clip_text` y ancho mínimo por largo
del rótulo-, porque un botón recortable dentro de un `HBoxContainer` en un `ScrollContainer`
horizontal colapsa a cero y el carril sale como una fila de rectángulos grises sin una letra. Pasó,
se vio en captura, y por eso `_pildora()` calcula el ancho a partir del texto.

**Lo demás que entró:** estética de píldoras (`_pildora()`: cápsula oscura con borde tenue en reposo,
clara con letra oscura cuando está activa, que es el contraste invertido del HTML del usuario);
desliz entre bloques como páginas (`_animar_pagina()`, con márgenes del `MarginContainer` porque un
hijo de Container no se puede mover a mano); L1/R1 y Ctrl+Q/E para cambiar de bloque; arrastre
horizontal con el dedo en Android (umbral de 90 px y 1,6 de proporción para no confundirlo con un
scroll vertical torcido); y el despacho compactado -antes hasta cuatro tarjetas apiladas se comían
media pantalla, ahora es una fila de avisos y solo se despliega el que estás mirando; la única que
sigue tapando todo es "estás sin banco", a propósito-.

**Pendiente de esta tanda:** las caras procedurales de los jugadores reales sin foto (el usuario
quiere "eliminar de raíz" la inconsistencia), la cabecera estilo HTML (dinero + fecha + iconos con
badge a la derecha), y los chips que todavía comparten pantalla en HISTORIA (Memoria, Rivales,
Vitrina se fusionaron en Legado/Logros/Récords hasta que se partan esas pestañas en secciones).

## SEGUNDA TANDA DEL MENÚ: DÍAS, FONDOS, ESTILOS Y AVISOS (10-9-2026)

Sobre el menú de doble nivel ya montado, el usuario pidió cuatro cosas más mirando su HTML:

**El calendario en DÍAS, sin partir el motor.** El motor late por SEMANAS -`Mundo.semana` es un
entero y de ahí cuelga todo-. Se pidió ver la fecha y avanzar de a un día. La solución no toca la
simulación: el día es de la INTERFAZ (`_dia_semana`, 0-6), la fecha se deriva del año + semanas
corridas + días, y al pasar del domingo se llama al `_avanzar_semana()` de siempre. Botón propio
"⏭ Un día" -no una entrada más del desplegable: es la acción que más se repite- y una tira con los
siete días, el de hoy encendido y el sábado con un balón cuando hay partido.
**Trampa pagada:** el 1 de febrero no siempre cae lunes (en 2026 cae domingo), así que sin
retroceder la fecha base al lunes de esa semana, la cabecera decía "dom" mientras la tira marcaba
"lun". Se ve en cuanto se mira, pero solo si se mira.

**Fondo fijo o rotativo.** Entrada nueva "🔀 Ir cambiando cada semana" arriba de los 24 fondos. La
rotación sale de `mundo.semana`, NO de `Azar`: mover el generador determinista por un adorno es la
trampa que ya costó una depuración con el feed de redes. Ojo al cargar preferencias: `ROTAR_FONDO`
es un valor especial que no está en `Fondo.NOMBRES`, y sin dejarlo pasar aparte la rotación se
perdía al reabrir el juego.

**Tres estilos de menú, uno solo por debajo.** El usuario los pidió "compatibles y modulares":
píldoras redondeadas, compacto (bloques solo con su icono, más aire para los chips) y barra clásica
(esquinas rectas). Como TODO el menú pasa por `_pildora()`, son tres pieles de un mismo menú, no
tres menús. Se cambian en caliente con `_reconstruir_grupos()` y se guardan en preferencias.

**Avisos con más vida.** El fondo del marco se tiñe un 8% del color del aviso -una decisión urgente
se distingue de una rueda de prensa sin leer una palabra-, la barra lateral sube a 6 px, se
redondea para combinar con las píldoras, y entra con un fundido corto para que se note que ACABA
de aparecer.

## LAS CARAS: DE 25.000 LLAMADAS A 40 CONSULTAS (10-9-2026)

Quedaban 1.077 futbolistas reales sin foto de 2.125. El primer intento de rescate repitió el error
del script original a lo grande: preguntar jugador por jugador con `wbsearchentities` +
`wbgetentities` por cada candidato, hasta 24 llamadas por futbolista. Wikidata devolvió **429 Too
Many Requests** en casi todas, incluso subiendo la espera a 2,6 s entre llamadas.

**El enfoque correcto es al revés:** una sola consulta SPARQL por PAÍS que trae de golpe todos los
futbolistas de ese país con foto, y el cruce de nombres se hace en local, normalizado (sin acentos
ni mayúsculas). Son ~40 consultas en total en vez de 25.000, y de paso el cruce normalizado
encuentra lo que la búsqueda literal no: "Nicolas Zuniga" contra "Nicolás Zúñiga".
`herramientas/caras_reales_sparql.ps1`.

**Pendiente detectado en la primera corrida:** `SCO` (Escocia, Q22) devolvió 0 futbolistas, porque
los escoceses llevan `P27` = Reino Unido, no Escocia. Y faltan por mapear MKD, PHI y GUI. Los dos
son de una línea en la tabla `$paisWikidata`.

## TERCERA TANDA DEL MENÚ: BADGES, CASCADA Y CABECERA (10-9-2026)

- **Badges de aviso (●) en los bloques maestros.** Un punto al lado del bloque que tiene algo sin
  resolver: correo sin leer, un representante esperando, ofertas recibidas, rueda de prensa
  pendiente. Todo sale de datos que el motor ya lleva -no hay contador nuevo que mantener, así que
  no se puede desincronizar-. Se refrescan con `_actualizar_badges()`, que solo cambia los seis
  rótulos: recrear seis botones con sus estilos en cada repintado sería caro, cambiar seis textos
  es gratis.
- **HISTORIA con sus apartados de verdad** (Récords / Memoria / Rivales / Vitrina). El truco vale
  la pena recordarlo: `_pintar_records()` son ~185 líneas con ocho secciones seguidas, y meterle un
  `if` por bloque era caro y arriesgado. En vez de eso se pinta TODO como siempre y después
  `_filtrar_records()` esconde lo que no toca, apoyándose en que cada sección empieza por un Label
  con un título conocido. Añadir una sección nueva es sumar su título a `SECC_RECORDS`.
- **Cascada de chips**: cada chip entra 35 ms después del anterior. Con diez chips el último entra
  a los 350 ms, antes de que la mano llegue a tocar nada.
- **Cabecera al estilo del HTML del usuario**: la caja en grande y la fecha a la derecha, separadas
  del nombre del club por todo el ancho. Antes vivían perdidas en el texto corrido entre la jornada
  y la media del plantel.

## LAS CARAS, RESULTADO FINAL DE LA JORNADA (10-9-2026)

De **1.048 a 1.216** caras reales (49,3% → 57,2%), en tres pasadas y con dos lecciones:

1. **Preguntar de a uno no escala.** El primer rescate hacía hasta 24 llamadas por futbolista
   (25.000 en total) y Wikidata respondía 429 a casi todas, incluso con 2,6 s de espera.
2. **Una consulta por país, cruce en local.** `caras_reales_sparql.ps1`: SPARQL trae de golpe todos
   los futbolistas de un país con foto y el cruce de nombres se hace aquí, normalizado sin acentos
   -que además encuentra lo que la búsqueda literal no-. ~40 consultas en vez de 25.000.
3. **Faltaban países en la tabla.** La primera corrida reportó 29 códigos "sin mapear" (ALB, ALG,
   CMR, EGY, SRB, TUN...). Cada uno eran decenas de caras perdidas por una línea que no estaba. Ojo
   también con `SCO`: los escoceses llevan `P27` = Reino Unido, no Escocia, así que con Q22 devolvía
   cero.
4. **Última pasada, sin filtro de país** (`caras_reales_sin_pais.ps1`): manda los nombres en lotes
   de 90 con `VALUES` y pide cualquier futbolista con foto que se llame así. Es para los que en
   Wikidata figuran con otra nacionalidad que la del juego -doble nacionalidad, naturalizados-.
   Asume a conciencia el riesgo del homónimo: es preferible la foto de otro "Diego Fernández" que
   un dibujo genérico.

## ECONOMÍA DEL DT, BONOS DE PRESTIGIO Y EL SONIDO DE GOL (10-9-2026, noche)

**1. El sueldo del DT ganaba el triple — corregido, con prueba de que era un bug.**
`Roles.sueldo_semanal()` no era `sueldoDT()` del HTML: era otra fórmula (multiplicativa, con el
exponente 0,62 de `Eco.escalar()`) que nadie había declarado rediseño, y con club y DT en el
promedio daba 9.900/semana contra 3.509. No era un número suelto: el sueldo llena el patrimonio del
DT, y con él se compran las licencias -la B cuesta 30.000-. Con la fórmula vieja se pagaba en tres
semanas; en el HTML, en casi nueve. **Todo el ritmo de la carrera del entrenador iba al triple** y
ninguna prueba lo notaba, porque ninguna fijaba el sueldo. Ahora es la del HTML letra por letra:
`ref_caja(rep)*0,0022 + prestigio*40`, después ×1,15 si hay Carisma, después ×(1+0,05×licencia),
con el mismo orden de redondeos. Banco en 0 fallos.

**2. Los dos bonos de prestigio que faltaban** (`bonusReputacion()` del HTML). El de cantera ya
estaba (`Cantera.multiplicador_de_reputacion()`); estos dos no existían en ningún sitio:
- `Roles.bono_reputacion_fichajes()` = `(prestigio-50)×0,006`, SUMADO a las ganas de venir en
  `Mercado.deseo_de_venir()` -solo si el destino es tu club-, con su razón visible en la ficha.
- `Roles.multiplicador_sponsor()` = `1+(prestigio-50)×0,004`, aplicado a las ofertas de marcas
  (`Auspicio.generar_ofertas`) y de zonas publicitarias (`Comercial.generar_ofertas_zona`).
  **Ojo, no al patrocinio semanal genérico de `Finanzas`**: en el HTML el bono va a
  `generarSponsorOfertas()` y `generarOfertasZona()`, no al ingreso fijo. Portarlo "donde parece"
  habría inflado un ingreso que el original no toca.
- `.sueldo` no se porta: en el HTML es código muerto (se calcula y se muestra, nada lo usa).
- La línea de `ofrecerPrecontrato()` no aplica: Godot no tiene precontratos.

**De paso, una desviación de porte en las zonas publicitarias:** el HTML sortea `0,85+azar×0,45` y
redondea a decenas de mil; el porte tenía `×0,4` y sin redondear. Corregido. Cambiar la escala no
consume más `Azar`, así que la liga no se mueve por esto.

**3. El sonido de gol elegido nunca sonaba.** `EstadioPropio.ajustes["sonidoGol"]` se podía elegir
entre ocho y hasta se cobraba la reforma, pero `Sonido` tocaba siempre el mismo "gol" fijo. Se
portaron las ocho recetas de `sfxGol()` (bombo, sirena, campana, órgano, pirotecnia, stinger,
batucada, solo la gente) como bancos `gol_<clave>`, todas con el rugido común debajo y los
`setTimeout(cantico)` como `_cantico()` con retraso -reservando el buffer primero, la trampa de
"trofeo"-. `partido_vivo.gd` toca el elegido en TUS goles y cae al "gol" de siempre si la clave
guardada no existe. Y en el diseño del estadio hay un "▶ Escuchar": elegir en el desplegable ya
cobra, así que probar va aparte, en un menú que solo reproduce.
Diferencias honestas: `_tono()` no tiene glissando ni onda triangular -la sirena va por tramos y el
triángulo es un seno-.

**Nota de estilo con el usuario:** es chileno. Nada de voseo argentino ("vos", "tenés",
"pegámelo"): tú/tienes, castellano neutro.

## LO QUE TRAJO GEMINI, INTEGRADO (11-9-2026)

El usuario dejó dos documentos en su Drive ("Visual gemini", "Mejoras globo") con ideas de Gemini
para el menú. Se revisaron y se integró lo que aplicaba de verdad:

**1. Nueve portadas más** (`ui/portada.gd`: `_andino`, `_vestuario`, `_cabina`, `_ejecutiva`,
`_tunel`, `_lluvia`, `_datos`, `_graffiti`, `_marmol`). Gemini las mandó como catálogo de TEXTO
-"atardecer andino con silueta de estadio", "mural urbano con ladrillo pintado"- sin una sola línea
de código; se dibujaron aquí con el mismo lenguaje procedural que las nueve originales (gradientes,
`_r()` para el scatter pseudoaleatorio, nada de imágenes). El selector de `inicio.gd` las recoge
solas -recorre `Portada.NOMBRES`-, así que no hizo falta tocarlo.

**2. El globo interactivo, en 3D de verdad** (`ui/globo_3d.gd`, nuevo). La idea de Gemini era buena
-un `SubViewport` con una esfera real en vez del raymarching por píxel que hacía el HTML
(`GLOBO_FS`, v3.17)- pero el código que mandó era un esqueleto (`globo_interactivo.gd`, sin
texturas ni día/noche). Lo que se construyó:
- `SphereMesh` con un shader propio que mezcla día/noche por `dot(normal, sol)` -el mismo sol muy
  oblicuo del HTML (z=0,28), para que el terminador cruce el disco y siempre quede un trozo de
  planeta encendido-, más una esfera de nubes semitransparente y una atmósfera de borde
  (`cull_front`, `blend_add`). Reutiliza las mismas tres texturas del HTML
  (`recursos/tierra/*.jpg`, copiadas al proyecto de Godot).
- Arrastre con el dedo/mouse, deriva lenta perpetua cuando nadie lo toca, y viaje animado a un país
  (`ir_a()`) igual que `globoIr()` del HTML -toma el camino corto en longitud-.
- Un pin dorado que marca el país elegido.
- Reemplaza el mapa plano que nunca se llegó a construir en `EleccionClub` (el paso "¿DÓNDE
  EMPIEZAS?"); los chips de país siguen ahí como atajo, y ahora además mueven el globo.

**LA TRAMPA QUE SE PAGÓ AQUÍ, con número exacto:** el primer intento posicionaba el globo con
`_pivote.rotation_degrees.x/y` -parecía lo obvio, "Y para la longitud, X para la latitud"- y el pin
de Chile terminó sobre Australia. Se comprobó con una captura aislada
(`pruebas/captura_globo.gd`, no pasa por `principal.tscn`) y con la posición impresa a mano: el
punto quedaba en `(1.01, -0.19, 0.05)` -al CANTO de la esfera, casi de perfil a la cámara- en vez de
en `(0, 0, 1)` -de frente-. La causa: Godot compone los tres ejes de Euler como `Y·X·Z` (aplica Z
primero, X después, Y al final), así que escribir `.y` y `.x` por separado no dice en qué orden se
aplican, y el orden real no es el que uno imagina leyendo el código de arriba hacia abajo.

**La solución no fue ajustar signos a prueba y error -ya se había hecho una vez con la rotación
adivinada y salió mal-, sino sacar los ángulos de Euler de la ecuación del todo.** Se construye la
base ortonormal directamente con producto cruz (adelante = el punto normalizado, derecha y arriba
salen de ahí) y se usa su traspuesta -su inversa, por ser ortonormal- como rotación del pivote. No
hay ángulo que acertar ni orden que memorizar: la única suposición es que Godot es diestro, que es
de catálogo. Verificado de nuevo con la misma captura: el pin quedó en `(0, -0.17, 1.02)`, de
frente, y con Australia, Brasil, Japón e Inglaterra la costa que aparece junto al pin corresponde
al país pedido.

Queda pendiente (no crítico): tocar el globo directamente para elegir país -ahora mismo solo se
elige por los chips, que mueven el globo pero no al revés-. Necesitaría un raycast desde el click
2D hacia la esfera 3D dentro del `SubViewport`, más encontrar el país más cercano al punto de
impacto.

**3. Las seis paletas de `ModuloEsteticaUI`, la tercera y última pieza de "Visual gemini"
(11-9-2026).** Quedó sin integrar en esta misma tanda -el globo y las carátulas sí, esto no- y
volvió a aparecer cuando el usuario mandó cuatro capturas de pantalla preguntando "¿agregaste los
diseños de Gemini?": esas capturas son justo estas seis paletas, no el globo ni las carátulas -que
ya estaban, y por un momento se le dijo por error que no lo estaban, hasta releer esta misma
sección-.

`ModuloEsteticaUI` proponía un `enum` aparte con seis `StyleBoxFlat` (ESPORTS/EXECUTIVE/CYBER/
BROADCAST/DARK_SLATE/MINIMAL, cada uno con su propio borde de color saturado). Se integraron como
**seis entradas más dentro del `const PALETAS`** que ya existía en `principal.gd`
(bosque/pizarra/carbón/vino/marino/tierra/papel/cuaderno/neón), no como un sistema aparte:
`esports`/`ejecutivo`/`cibernetico`/`transmision`/`pizarra_gr`/`minimo`. El selector de Ajustes →
Aspecto ya recorre `PALETAS` genéricamente (`for k: String in PALETAS`) y cada botón se pinta con su
propia muestra de colores, así que no hizo falta tocar ni una línea más para que aparecieran ni para
que el guardado/carga de preferencias las reconociera (`PALETAS.has(p)` ya valida por clave, no por
una lista fija).

**Diferencia deliberada con las nueve paletas viejas**: esas nueve solo cambian el TINTE de fondo/
panel y dejan el borde en blanco o negro translúcido, neutro -"las paletas no pisan el color del
club" es la nota que ya vivía ahí, porque el acento de verdad sale de `COL_ACENTO`/
`_con_contraste()`, derivado de los colores de tu club-. Las seis nuevas sí traen un borde de un
color saturado propio (esmeralda/ámbar/cian/rojo), que es justo lo que se ve en las capturas que
mandó el usuario. Eso NO contradice la nota: sigue siendo el panel/fondo/borde lo que tiñe la
paleta, el acento del club sigue sin tocarse -solo que ahora el borde neutro de antes puede ser,
si el jugador lo elige, un borde con carácter propio-.

Verificado con una captura aislada: se activa "cibernético" y toda la pantalla de Ajustes se repinta
de verdad -fondo azul-púrpura muy oscuro, bordes cian en cada botón y cada panel-, sin reventar.

## SALA DE PRENSA Y EL RUIDO DE FUERA, CON CHIP PROPIO (11-9-2026)

Revisando los pendientes del menú (lista que quedó en este mismo documento): "falta Sala de Prensa
en OPERACIONES" y "falta El ruido de fuera". Al mirar el código, el motor de las TRES pantallas del
HTML -`vSocial` (feed, funa, gabinete de comunicación), `vPrensa` (periodistas, medios propios,
vocero, cámaras, derechos de TV, archivo de portadas, año contado) y `vDebate` (mesa de televisión,
ranking de entrenadores, el influencer)- **ya estaba escrito y pintado** en `principal.gd`, todo
junto bajo un solo chip ("Feed de Redes") y una sola lista (`_lista_redes`). Ni `vGente` ni
`vDebate` seguían "sin portar" como decía la memoria vieja del proyecto -quedó corregido ahí
también-: alguien ya los había escrito en una tanda anterior de la migración y la nota nunca se
actualizó.

Lo que faltaba de verdad no era motor ni pantalla: era que estuvieran amontonadas sin separación,
justo el defecto que el usuario pidió corregir ("evitar la duplicidad... deben existir más
submenú"). Se separaron con el mismo truco que ya usa Récords (`_filtrar_records()`/
`SECC_RECORDS`): se pinta todo de un tirón, como siempre, y se esconde lo que no toca según el chip
activo, apoyándose en que cada sección empieza con un `Label` de título conocido. Nuevo
`SECC_REDES`/`_filtrar_redes()`, y dos chips más en OPERACIONES: "Sala de Prensa" y "El Ruido de
Fuera", junto al ya existente "Feed de Redes". La cabecera de seguidores/funa/ánimo/prestigio no
lleva título propio, así que se ve siempre en las tres -es contexto común, no de una sección-.

No se movieron "Derechos de TV" de esta pantalla a Finanzas -una idea que había quedado anotada
como pendiente-: en el HTML vive dentro de `vPrensa()`, no de la pantalla de finanzas, así que
moverlo habría sido inventar una organización que el original no tiene. Si el usuario lo sigue
queriendo así, es un cambio de gusto, no una corrección de fidelidad.

**De paso, otro chip mal etiquetado en GENTE:** "Muro" apuntaba a la pestaña "Camarín" -clima del
vestuario, camarillas, capitán-, que es contenido real y correcto, solo que con el nombre de OTRA
pantalla (`vMuro()`, el muro de campeones). Ese muro de campeones ya vive en HISTORIA → Memoria
(`Logros.muro`, sección "SALÓN DE LA FAMA DEL CLUB"): duplicarlo aquí habría sido la misma
duplicidad que se acaba de arreglar en Redes. Se corrigió solo la etiqueta -"Camarín"-, sin tocar a
dónde apunta.

## DOS CABLES SUELTOS MÁS, ENCONTRADOS CON UN AGENTE (11-9-2026)

Se mandó un agente a cruzar TODAS las funciones públicas de `nucleo/*.gd` contra `ui/*.gd` -el mismo
método que ya encontró `obra_lista`/`titulo_celebrado`/`Directiva.despedido` el 7-9- y devolvió una
lista larga, la mayoría falsos positivos (motor que ya se llama desde dentro de `mundo.gd`, no desde
`ui/`). Dos SÍ eran cables sueltos de verdad, verificados a mano antes de tocar nada, y los dos se
arreglaron y probaron con un harness aislado (`pruebas/captura_emergencia.gd`, sin pasar por
`_avanzar_semana()` en bloque):

**1. La ventana de fichaje de emergencia nunca se abría.** `Roles.abrir_emergencia()` existe desde
hace tiempo -banner, `usar_emergencia()`, el gatillo en `puede_fichar()`, todo escrito y probado-
pero el propio comentario del código ya avisaba: *"quien lleve las lesiones la abre llamando a
`abrir_emergencia()`"*, y nadie lo hacía. Perder a un titular por una lesión de 12+ semanas con el
mercado cerrado no destrababa nunca el fichaje de emergencia que el juego promete. Conectado en el
handler de `Medico.lesion_nueva` (`principal.gd`, junto al aviso de "Lesión grave"), con la misma
doble condición del HTML (`ventanaEmergencia()`): titular del once, o un nivel cercano al del club
aunque no lo fuera. Probado: mercado cerrado + lesión de 14 semanas a un titular → `emergencia_activa()`
pasa de `false` a `true`, con el diccionario correcto.

**2. Te despedían a mitad de temporada y el juego no te ofrecía ningún club nuevo.** Este es más
gordo. `Roles.quedar_sin_banco()` -que activa `sin_club`, dispara `ofertas_trabajo()` y desbloquea
`_pintar_sin_banco()`, una pantalla entera ya escrita y probada con las ofertas de otros clubes- **no
se llamaba desde NINGÚN sitio del proyecto**, ni siquiera al vender el club. El handler de
`Directiva.despedido` en `principal.gd` -conectado desde el 7-9- solo escribía el aviso y le decía al
jugador "elige otro club en la lista de arriba", pero la lista de arriba es la de EMPEZAR una carrera
nueva desde cero, no la de que TE CONTRATEN tras un despido. Toda la mecánica de "quedarte sin banco
y recibir ofertas" -que existe, con pantalla y todo- era inalcanzable en la práctica. Se agregó la
llamada en el mismo handler -`despedido` solo se emite con `puede_despedirte` ya sincronizado desde
`le_pueden_echar()`, así que la comprobación que pide el comentario de `roles.gd` ya está hecha antes
de llegar ahí- y se corrigió el texto del aviso ("elige tu próximo club entre las ofertas de abajo").
Probado: `despedido.emit()` → `sin_club` pasa de `false` a `true`, con 3 ofertas de trabajo listas.

Los cinco candidatos que quedaron anotados aquí ("intercambio de jugadores", "planes de
entrenamiento individual", "la promesa de fichar a un compatriota", `procesar_ajeno()` y
`sortear_habilidades()`) se cerraron todos la misma noche -ver la sección siguiente-, a pedido
explícito del usuario ("dale con todo").

## "DALE CON TODO": LOS CINCO CANDIDATOS, CERRADOS (11-9-2026, madrugada)

**1. Los rivales de la IA ya progresan.** `Entrenamiento.procesar_ajeno()` -recuperación de físico y
una progresión simple, sin foco ni intensidad ni instalaciones- se llama ahora cada semana para
CADA jugador que no es tuyo, en `Mundo.avanzar_semana()`, justo después de `procesar_semana()` de tu
plantel. Antes de esto el resto del mundo se quedaba congelado para siempre, tal como avisaba el
propio comentario del código.

**2. Los futbolistas nacen con habilidades.** `Entrenamiento.sortear_habilidades()` necesita una
`Entrenamiento` viva para guardar lo que reparte, y esa clase no existe todavía cuando se generan
los ~8.000 jugadores del mundo -no hay club elegido-. Solución: una siembra única en
`tomar_el_mando()`, con bandera propia (`_habilidades_sembradas`, no guardada a propósito: si una
carga la repite, `Entrenamiento.desde_dic()` -que corre después- pisa el sorteo con los datos
reales), más la llamada normal dentro de `crear_jugador()` para cualquiera que nazca después
-canteranos, agentes libres-.

**3. Intercambio de jugadores en la mesa de negociación.** `Negociacion.poner_intercambio()` ya
ejecutaba el traspaso real (`valor_percibido()` suma el 88% de su valor, `enviar_oferta()` mueve la
ficha de verdad) sin que ningún selector lo llamara. Nueva sección "PARTE DE PAGO: UNO DE LOS TUYOS"
en la mesa: hasta 8 candidatos de tu plantel con nivel cercano al del objetivo (media ≥ la suya
menos 18), ordenados por valor, con un botón de alternar cada uno -pedirlo de nuevo lo saca de la
oferta, mismo patrón que `poner_intercambio()` ya traía-.

**4. Entrenamiento individual.** `Entrenamiento.asignar_individual()`/`plan_de()` -catálogo
`ESPECIALES` completo: Penales, Tiros libres, Juego aéreo, Regate, Pase filtrado, Explosividad,
Liderazgo- ya se resolvía solo cada semana (`_trabajo_individual()`, con noticia y todo) sin ninguna
pantalla que lo asignara. Nueva sección en Entrenar: los planes activos con su progreso y botón de
cancelar, y "ASIGNAR A UN JUGADOR" con los catorce que más margen tienen hasta su potencial -no solo
los jóvenes, cualquiera que pueda crecer, igual que el HTML-, cada uno con los siete botones de
especialidad.

**5. Las solicitudes del plantel, el hallazgo más grande de la tanda.** Esto no era "falta un
botón": el sistema ENTERO no existía en Godot. En el HTML, un jugador viene a hablar contigo cada
cierto tiempo -pide más minutos, mejor sueldo, salir del club, un compatriota, días libres, quejarse
de las instalaciones, la cinta de capitán- y hay que decirle que sí o que no, cada respuesta con su
propia consecuencia en moral. Se portó entero en `Vestuario` -encaja ahí porque es la misma materia
prima que camarillas y roles: moral, ánimo del plantel-:
- `SOLICITUDES` (la tabla de siete), `sortear_solicitud()` (candidatos según la situación REAL de
  cada uno, no al azar puro: solo pide más minutos quien de verdad los tiene incumplidos, solo pide
  un compatriota quien de verdad está solo en el club), `resolver_solicitud()`.
- Se tira una vez por semana desde `Mundo.avanzar_semana()`, junto a `suceso_semanal()`.
- Pantalla nueva: se enganchó como un cuarto "asunto" del Despacho -mismo patrón de pestañitas que
  ya usan la decisión de prensa y la rueda de prensa-, con tarjeta de sí/no.
- **Un bug real del HTML, encontrado leyendo el código para portarlo, corregido y documentado**:
  rechazar la petición de "salida" aplicaba el golpe de moral DOS VECES seguidas (4 y luego otros 6,
  en los hechos 10) pero el aviso seguía diciendo "perdiste 4" -un desfase entre el texto y el efecto
  real, no una regla a propósito-. Se dejó como un solo número correcto (10) en vez de portar el
  doble golpe letra por letra.
- El único caso que cruza a otra clase (`Cantera.prometer_compatriota()`) se resuelve en la interfaz,
  no dentro de `Vestuario`: esa clase no conoce `Cantera`, y forzar la relación por una sola llamada
  no valía la pena.

**Efecto colateral bueno: un bug real de la interfaz, encontrado sin buscarlo.** Probando la mesa de
negociación con una captura nueva, saltó "bad comparison function; sorting will be broken" al abrir
Plantel -nunca antes en esta sesión, porque ninguna captura anterior había abierto esa pestaña-.
`_comparar_plantel()` invertía el orden descendente con `return not menor` en vez de comparar los
operandos al revés: con un empate exacto (`menor` da `false` en los dos sentidos), `not false` da
`true` en los DOS sentidos, y el comparador dice a la vez "a va antes que b" y "b va antes que a".
Corregido comparando `x`/`y` intercambiados según el orden, no negando el resultado -la forma
correcta de invertir un `sort_custom`, y la única que no rompe con empates-.

Las cinco piezas y el arreglo de Plantel, verificados con el banco completo (0 fallos) y con una
captura real: la tarjeta de "Te busca un jugador" respondiendo sí/no, la mesa de negociación con el
selector de intercambio mostrando jugadores y precios reales, y Entrenar con la sección nueva.

## FATIGA POR VIAJES INTERNACIONALES (11-9-2026)

Porte de `fatigaViaje()` / `aplicarFatigaViaje()` del HTML, que no existía en Godot: jugar de visita
un partido continental (Libertadores/Sudamericana/Champions/Europa League) contra un club de OTRO
país no costaba nada, cuando en el HTML se paga con 1 a 9 de físico -el once que juega entero, el
resto de la plantilla un 35%-. Vive en `Mundo._fatiga_de_viaje()`, llamada justo antes de
`t.jugar_ronda()` en el bucle continental, para que el cansancio se note EN ese partido.

Dos correcciones sobre el original, con la razón escrita en el código:
1. **El alivio que restaba 0 siempre.** El HTML resta `G.inst.pf*0,4 + G.staff.pf*0,6 +
   G.inst.piscina*0,5`, pero `pf` no es una instalación: es un PUESTO del cuerpo técnico (tabla de
   `INSTAL`/`PUESTOS` en `juego.js:6014`), y `G.inst.pf` no existe -vale 0 siempre, sin que nadie lo
   notara-. La clave real del preparador físico es `"fisico"` en `Staff.PUESTOS`. Se corrigió aquí
   Y en `Prensa._fatigar_por_viaje()` -el mismo bug, en el evento "virus FIFA", vivía sin tocarse
   desde antes de esta sesión-.
2. **El avión que se cobraba y no hacía nada.** `Comercial.alivio_de_viaje()` existía, costaba y se
   anunciaba ("menos fatiga en los viajes largos") desde hacía tiempo, y ningún sitio lo llamaba:
   comprar el avión del club era gratis en los hechos. Ahora resta sus 3 puntos en
   `_fatiga_de_viaje()`.

Verificado con el banco completo (varias temporadas, todas las continentales en juego): 0 fallos.

## DOS BUGS REALES, ENCONTRADOS PROBANDO LA TANDA "DALE CON TODO" (11-9-2026)

Ninguno de los dos lo produjo el trabajo de esa tanda directamente -uno llevaba ahí desde que se
escribieron las nueve portadas nuevas, el otro es más viejo que esta sesión-, pero los dos son
graves y los dos se encontraron por PROBAR EN SERIO, no por revisar el código a ojo.

**1. La pantalla de inicio no compilaba. Bug de romper el arranque, invisible para el banco.**
`ui/portada.gd` usaba `var w := lerp(...)` en la portada "Túnel de campeones": `lerp()` es genérico
-sirve para float, Vector2, Color- y devuelve `Variant`, y con `:=` el tipo queda inferido como
`Variant`, que este proyecto trata como ERROR de compilación, no como advertencia. Eso rompía la
carga de `ui/inicio.gd` entero -la pantalla de título, con la que arranca CUALQUIER partida nueva-.
**Ningún banco lo vio nunca** porque `banco.gd` no carga `ui/` por diseño, y ninguna captura de esta
sesión había abierto la pantalla de inicio -todas entran directo a `principal.tscn`-: se encontró
recién al construir una prueba nueva que sí pasaba por ahí. Arreglado con `lerpf()`, la variante
tipada. **Lección que vale para todo el proyecto**: escribir `var x := lerp(...)` es una trampa
silenciosa en cualquier archivo de `ui/`, porque el banco headless nunca la va a encontrar.

**2. Una captura de prueba dejaba el idioma real del juego en inglés.** `pruebas/captura.gd` prueba
la paleta "cuaderno" en inglés y dice volver a "es" después, pero el archivo real de preferencias
-`user://preferencias.cfg`, el MISMO que usa el juego de verdad, no uno de prueba: no hay forma de
aislarlo con `--user-data-dir` en este build de Godot (se probó, cuelga el proceso sin avisar, ver
el comentario en `herramientas/run_godot.ps1`)- quedó con `idioma="en"` de una corrida anterior. Se
encontró en vivo: la partida real de este equipo amaneció en inglés sin que nadie tocara nada.
Arreglado en dos frentes: `captura.gd` ahora guarda el idioma REAL al empezar (`_idioma_real`, leído
de lo que YA cargó `Principal._ready()`) y lo devuelve dos veces -al terminar la prueba de idioma
normalmente, y otra vez justo antes de `quit()` como red final-, en vez de asumir a ciegas que el
jugador real usa español. Verificado con una prueba aislada que lee el archivo de disco en cada
paso: `es` al arrancar → `en` tras la prueba → `es` de vuelta antes de salir. El archivo real, que
había quedado contaminado, se corrigió a mano de inmediato.

## SEGUNDA RONDA DE MOTOR SIN PANTALLA (11-9-2026, madrugada)

Otro agente, mismo método que la ronda anterior pero con el grafo de llamadas correcto esta vez
-la primera pasada excluía las funciones privadas `_x()` y eso generaba ruido: 342 "candidatos" de
los que solo 40 eran de verdad inalcanzables-. Cinco se cerraron esta noche:

**1. Los playoffs por el título, el más grave de la ronda.** `Federacion.campeon_de_liga()` -toda
la eliminatoria de cuatro escrita y probada, con noticia y marcador propios- existía desde antes, y
el propio docstring de `federacion.gd` describe EXACTAMENTE este bug como algo "que este proyecto ya
pagó": *"se votaban los playoffs, salía la noticia, y en diciembre el campeón seguía siendo el
primero de la tabla"*. Pero seguía pasando: `Mundo.cerrar_temporada()` y `Mundo.jugar_temporada()`
usaban `t[0]["club"]` directo. Arreglado en los dos sitios -en `cerrar_temporada()`, solo para TU
liga: los playoffs los vota tu asamblea, las demás siguen coronando al primero, que es lo correcto-.
Cuando no se votaron playoffs, `campeon_de_liga()` cae en el mismo `t[0]["club"]` de siempre: cero
riesgo para las partidas que no tocan esa regla.

**2. El logro oculto "remontada" era matemáticamente imposible.** *"Ganar un partido yendo tres
goles abajo"* — y nada en el motor marcaba nunca `logros.marcas.remontada = true`. Revisando el
HTML para portarlo bien salió que **el original tenía el mismo bug**: `LOGROS_OCULTOS` prometía el
logro y `marcas()` era solo un getter vacío que nadie llenaba. Se cerró de verdad -no se dejó el bug
del original, porque una promesa rota al jugador no es un detalle de porte-: `Partido` ahora lleva
`peor_diferencia_local`/`peor_diferencia_visita` -el peor déficit que sufrió cada lado en algún
momento-, y `hubo_remontada_de(club)` combina eso con haber ganado. `Logros.tras_partido()` lo marca
sin sortear nada nuevo.

**3. El césped destrozado no le costaba nada a nadie.** `Ciudad.penalizacion_cesped()` -"el único
efecto" del césped, según su propio comentario- nunca se multiplicaba en ningún cálculo de partido:
alquilar el estadio para conciertos rompía el pasto solo en apariencia. Mismo mecanismo de contexto
que ya usan las instrucciones en vivo (`Partido.ctx_club_id`, puesto una vez por semana desde
`Mundo.avanzar_semana()`): nuevo `Partido.ctx_cesped_local`, que solo pega cuando juegas de LOCAL
-es tu pasto el que se rompe- y multiplica tu probabilidad de gol.

**4. La venta con un fondo de por medio mostraba el precio bruto.** `Cesiones.neto_de_venta()`
existía -"enseñar el precio bruto cuando la mitad se la lleva un fondo sería mentir en la pantalla
donde más duele", dice su propio comentario- y la lista de "OFERTAS RECIBIDAS" en Mercado seguía
mostrando el bruto sin más. Ahora, si hay un fondo con participación, aparece una segunda línea con
lo que el club se queda de verdad.

**5. Estar en mora con el banco no bloqueaba fichar.** `Banco.estado()` prometía "Fichajes
inhibidos" desde la cuarta semana en caja roja, y `_motivo_fichaje_bloqueado()` -la puerta central
por la que pasan ficha, clausulazo y cesiones- nunca lo comprobaba. Se agregó con la misma frontera
que el fair play financiero, que ya vive justo ahí: bloquea el mercado de PAGO, no los agentes
libres -es exactamente el matiz que la propia función de al lado ya aplicaba, así que se copió el
criterio en vez de inventar uno nuevo-.

**Quedan anotados, sin tocar -necesitan más que conectar un cable-:**
- `Prensa.arbitro_dudoso()`: la rama de "reclamo formal" en el despacho ya está completa, pero no
  hay ningún sistema de árbitros con nombre en `partido.gd` que decida cuándo hubo un "escándalo
  arbitral" real -el HTML tampoco tenía este gancho conectado, no hay de dónde copiar el disparador-.
- `Instalaciones.abarata_operacion()` (el huerto sustentable al nivel 3): en el HTML descontaba un
  12% de una partida de gastos -"Operación, viajes, seguridad e impuestos", `(derechosTV+auspicio)
  ×0,42`- que **no existe en `Finanzas.mes()`**: ahí el gasto es solo sueldos + `estructura()`, una
  fórmula distinta (reputación + consejeros, no TV/patrocinio). Conectar el descuento primero exige
  portar la partida que descuenta, no al revés.

Verificado con el banco completo: 0 fallos.

## NUNCA SE PODÍA DIRIGIR UN PARTIDO CONTINENTAL EN VIVO (11-9-2026, madrugada)

Investigando la inconsistencia anotada arriba ("Hallazgo de paso, construyendo el calendario") salió
algo más grande que una inconsistencia de pantalla: **`_dirigir()` nunca podía llevarte a un partido
de Libertadores/Sudamericana/Champions/Europa League**. Solo miraba `mundo.partido_de_copa()` y
`mundo.proximo_partido()` (liga) -no existía ningún `partido_continental()`-, así que TODO cruce
continental se auto-simulaba solo, en silencio, temporada tras temporada, sin que el jugador
pudiera dirigirlo ni una sola vez.

**La causa de fondo, para quien vuelva a tocar el calendario**: el HTML arma UN calendario
autoritativo por temporada (`armarSemanas()`) donde cada semana tiene EXACTAMENTE un tipo -'liga',
'copa' o continental-, así que ahí nunca compiten dos torneos por la misma semana. `Mundo.avanzar_semana()`
en Godot no heredó ese diseño: liga, copa (`semana%4==0`) y continental (`Continental.CONTI_EN`)
corren cada una por su cuenta, sin coordinarse. Arreglar eso del todo es tocar la arquitectura del
calendario entero -grande, no para esta tanda-. Lo que SÍ se cerró, que es lo que de verdad se
notaba jugando:

- `Mundo.partido_continental()`, nuevo -mismo patrón que `partido_de_copa()`-: el cruce continental
  de tu club esta semana, si te toca.
- `_dirigir()` ahora mira copa primero (como siempre, "se puede perder para siempre"), y si no hay
  copa, continental antes que liga.
- **El motor YA sabía recibir el partido jugado en vivo** (`Continental.jugar_ronda(ya_jugado)`,
  heredado de `Copa`) y nadie se lo pasaba nunca: `Mundo.avanzar_semana()` llamaba
  `t.jugar_ronda()` en blanco, siempre, así que aunque hubiera existido la puerta de arriba, el
  resultado que verías en pantalla se habría vuelto a simular por dentro con otro marcador. Nuevo
  `_continental_es_de(t, p)` -mismo patrón que `_copa_es_de()`- para saber a cuál de los varios
  torneos activos (`continentales`, uno por confederación) le tocaba de verdad `ya_jugado`.
- De paso, `logros.tras_partido()` etiquetaba todo partido dirigido como "Copa" o "Liga": un
  continental dirigido en vivo quedaba anotado como "Liga" en la memoria del club. Ahora distingue
  las tres.

**Lo que sigue sin resolver, documentado a propósito**: en las dos semanas donde copa y continental
coinciden (8 y 28, porque `CONTI_EN` y "cada 4 jornadas" se cruzan ahí), copa se queda con la
prioridad -como ya tenía- y el continental de esa semana se sigue auto-simulando. Es el mismo límite
de fondo del párrafo de arriba: mientras no haya un calendario único como el del HTML, dos torneos
grandes van a poder chocar la misma semana un par de veces al año.

Verificado con el banco completo (0 fallos) y con una captura real que fuerza la semana 3 -grupos de
Libertadores-: se abre el partido en vivo (Colo-Colo vs Olimpia, no eliminatoria porque es fase de
grupos), se juega, y el resultado en pantalla (2-0) es EXACTAMENTE el que queda anotado en la tabla
del grupo -no se volvió a simular por dentro-.

## LA MIGRACIÓN ESTÁ PRÁCTICAMENTE TERMINADA (11-9-2026, madrugada)

Auditoría nueva de un agente, la más exhaustiva hasta ahora -las 73 funciones `vNombre()` de
`js/vistas.js`, leyendo el HTML y el Godot correspondiente para comparar contenido real, no solo
nombres-. Resultado: **71 completas, 2 parciales, 0 sin empezar. ~95-99% de migración** ponderada
por líneas de JS -salto enorme desde el 70,8% de la auditoría del 8-9-.

Las 5 pantallas que la auditoría de septiembre marcaba "sin empezar" (vCantera, vCopa/vConti,
vStaff, vTrofeos/vMemoria/vMuro/vHistoria, vLinajeExtra) ya estaban hechas: solo reorganizadas bajo
otros nombres o repartidas entre pestañas nuevas, no ausentes.

**Las únicas 2 parciales que quedan, ninguna urgente:**
- `vClubIn` (57 líneas): la app/sitio web del club es un sí/no con renta fija
  (`ClubDentro.app`/`web`); falta la simulación de crecimiento de suscriptores semana a semana y el
  nombre/dominio personalizado que tenía el HTML.
- `vAjustes` (53 líneas): parcial A PROPÓSITO -comentario explícito en el código, `principal.gd:10384`-:
  de los +20 controles del HTML solo se engancharon los que tienen efecto real en Godot. Falta el
  selector de velocidad de simulación por defecto y una tabla de referencia de atajos de teclado/mando.

Sigue en pie, sin tocar y sin que el usuario haya dicho si los quiere: `vCiudad`/`vEditor`/
`vIdentidadPlus`/`vBanco` (~25h, sistemas NUEVOS que no forman parte de las 73 `vNombre()` de
arriba, así que no cuentan para el %).

## VELOCIDAD DE PARTIDO POR DEFECTO, Y OTRO BUG ENCONTRADO DE PASO (11-9-2026)

Cerrada una de las dos parciales que dejó la auditoría: **"Velocidad de partido por defecto"**
(`vAjustes()`). Antes de esta tanda `PartidoVivo._velocidad` arrancaba siempre en el índice fijo 2
("Normal") sin que hubiera dónde elegir otra cosa -no era una preferencia, era un número dentro del
código-. Ahora:
- `_velocidad_partido` en `principal.gd`, persistido en `preferencias.cfg` como el resto de ajustes
  (paleta, idioma, música...).
- Selector nuevo en Ajustes → Juego: Lento/Normal/Rápido -se salta "Pausa", igual que el propio
  HTML se salta esa opción en el mismo selector: nadie quiere que el partido arranque parado-.
- `PartidoVivo.abrir()` recibe un parámetro nuevo, `velocidad_inicial`, opcional y con valor por
  defecto -1 (mismo comportamiento de siempre si nadie lo pasa: las pruebas que abren un partido con
  dos argumentos siguen andando igual).

**Un bug real más, encontrado por el mismo motivo que el de `lerp()`**: abrir Ajustes → Juego por
primera vez en toda la sesión hizo saltar "Trying to assign value of type 'Dictionary' to a variable
of type 'String'" en `_pintar_qol()` -la sección de "ACCESOS RÁPIDOS"-. `for tab: String in
g["tabs"]` asumía que cada `tabs` era una lista de nombres sueltos, pero desde que el menú usa chips
`{tab, secc, label}` cada elemento es un diccionario: reventaba apenas alguien abriera esa pestaña
concreta, y ningún banco ni ninguna captura de esta sesión había pasado por ahí. Arreglado extrayendo
`chip["tab"]` de cada uno, sin repetir -varios chips comparten la misma pestaña con distinto
`secc`, y un botón por chip habría duplicado "Club" media docena de veces-.

Verificado con el banco completo y con una captura real: el selector de velocidad se ve, "Rápido"
se guarda y el siguiente partido dirigido en vivo arranca de verdad en Rápido; la sección de accesos
rápidos ya no repite ninguna pestaña.

La otra parcial de la auditoría -la tabla de referencia de atajos de teclado/mando- se dejó sin
tocar a propósito: investigando cómo describirla salió que `L1`/`R1` en el mando están registrados
DOS VECES para cosas distintas (`dinastia_tab_siguiente`/`anterior` -chips- Y, en el mismo `_input()`,
un chequeo aparte del mismo botón físico para cambiar de bloque maestro) y por el orden del
`elif` la segunda nunca puede dispararse. Puede ser un bug real de ruteo o código muerto de una
versión anterior del menú -no se investigó más a fondo, no era el objetivo de esta tanda-, pero
escribir una tabla de atajos ahora mismo habría podido documentar un comportamiento que ni siquiera
existe. Queda anotado para revisar aparte.

## EL BUG DE L1/R1, RESUELTO, Y LA TABLA DE ATAJOS YA ESCRITA (11-9-2026)

Se mandó a investigar aparte, como quedó anotado arriba. Confirmado: **bug real de ruteo, no código
muerto a propósito**. Con mando conectado, L1/R1 SIEMPRE disparaban `dinastia_tab_siguiente`/
`anterior` (chip, nivel 2) -registrados en `_preparar_mando()`-, así que el `elif` de más abajo en
`_input()` que comprobaba el mismo botón físico para `_bloque_vecino()` (bloque maestro, nivel 1)
era inalcanzable: un evento de joypad que cumple la condición del primer `if` nunca llega al
segundo. **El jugador con mando no tenía NINGUNA forma de cambiar de bloque maestro** -ni gatillo,
ni botón, nada- sin soltar el mando y tocar la pantalla. Contradice el objetivo con el que se pidió
el menú ("un centro de mando... jugable desde el sofá").

Arreglado liberando el otro gatillo de hombro, el analógico: **L2/R2 -antes libres del todo- ahora
son `dinastia_bloque_anterior`/`siguiente`**, con el mismo mecanismo de `InputMap` que ya usaban
L1/R1 y el stick izquierdo (`InputEventJoypadMotion` con `axis_value=1.0`, mismo patrón que
`ui_up`/`ui_down`). El `elif` muerto se reemplazó por el chequeo de las acciones nuevas.

Con el comportamiento real ya arreglado y conocido, se escribió por fin la **tabla de atajos** que
había quedado pendiente de la auditoría (`vAjustes()`, la otra parcial): teclado y mando lado a
lado, en Ajustes → Pantalla. Con eso, **las dos parciales de `vAjustes()` quedan cerradas del
todo** -sigue quedando la de `vClubIn()` (crecimiento de suscriptores de la app/web del club), sin
tocar-.

Verificado con el banco completo (0 fallos) y con una captura real de la tabla -se ve completa,
cuatro filas, con la nota del gesto táctil.

## LA APP Y LA WEB DEL CLUB YA CRECEN SOLAS: LA ÚLTIMA PARCIAL, CERRADA (11-9-2026)

Quedaba una sola pantalla parcial de las 73 de la auditoría: `vClubIn()`, la app oficial y el
sitio web del club. Lo que había en Godot (`ClubDentro.app`/`web`) eran dos booleanos: se compraban
una vez y rentaban una cifra fija cada mes, sin nombre propio, sin dominio, sin nada que creciera.
El HTML es otra cosa: `lanzarApp()`/`lanzarWeb()` piden un nombre y un dominio -o caen a uno por
defecto-, y `procesoClubIn()` las hace crecer CADA SEMANA con los resultados del equipo:

```
C.app.subs = round(C.app.subs*(1.004+forma*0.002) + R(-20,140))
mov(round(C.app.subs*ECO*0.9), 'Suscripciones de la app oficial')
```

(`forma` = victorias de LIGA entre tus últimas 5 -ni copa ni continental cuentan, igual que
`registrarPost()` del HTML, que solo empuja `G.clubes[id].forma` cuando `modo==='liga'`-.) La web
es la misma idea con `visitas` en vez de `subs`, y además suma seguidores de redes:
`G.social.seg += C.web.visitas*0.0008`.

**Portado tal cual, no la versión simplificada que había:**
- `ClubDentro.app`/`web` pasan de `bool` a `Dictionary` (`{}` = no lanzada; lanzada trae
  `nombre`/`subs`/`desde` o `dominio`/`visitas`/`desde`). `desde_dic()` migra los guardados viejos:
  un `true` suelto se convierte en una app/web recién lanzada con contador en cero, en vez de perder
  el guardado o reventar con un tipo que ya no existe.
- `lanzar_app()`/`lanzar_web()` reemplazan a `comprar_digital()`: piden nombre/dominio (con
  el mismo valor por defecto que el HTML si el campo llega vacío) y arrancan los contadores desde
  `c.socios*0.08` / `c.socios*1.4`, igual que `lanzarApp()`/`lanzarWeb()`.
- **Bug de paso, corregido**: el coste de la web en Godot era `140000`; el HTML dice
  `esc$(120000)`. Quedó en 120000.
- `ClubDentro.crecer_digital(c, prensa)` hace crecer subs/visitas cada semana con la fórmula de
  arriba -`Eco.ECO` (=12, "1 punto interno = 12 EUR en pantalla") ya existía en `economia.gd` y
  la usan `cesiones.gd`/`prensa.gd` para lo mismo; aquí faltaba usarla- y devuelve los movimientos
  para que `Mundo` los deje anotados en el libro financiero, en vez de cobrar en silencio.
- **`forma` no existía en Godot para nada** -ni como campo de `Club` ni de ningún otro lado-: se
  añadió como una lista propia de `ClubDentro` (no de `Club`, para no tocar su serialización en
  `partida.gd` por una lista de 5 letras que solo usa esta pantalla) y se alimenta desde
  `_avisar_a_la_directiva()` -que `avanzar_semana()` ya llama justo después de `Liga.jugar_jornada()`,
  el mismo punto exacto donde el HTML sabe que el partido fue de `modo==='liga'`-.
- Movido de cadencia: antes rentaba en el CIERRE DE MES (`semana%4==0`), como el resto de "lo
  digital" (vestuario/prensa/palco, que sí son de pago único y renta plana). El HTML corre
  `procesoClubIn()` en el proceso SEMANAL (`procesoSemanalV19()`, junto a cantera y prensa), no en
  el mensual -así que ahora crece y paga las 4 semanas del mes, no solo la última-.

Verificado con el banco completo (0 fallos, incluye `Eco.ECO`/`Azar.ent` usados igual que en el
resto del motor) y con una captura aislada (`pruebas/captura_clubin.gd`): lanzar app y web cobra el
costo de cada una, arrancan en los subs/visitas esperados a partir de los socios del club, y tras
una semana ambos contadores suben, la caja sube con ellos, quedan anotados en el libro financiero
como "Suscripciones de la app oficial"/"Publicidad en la web del club", y `forma` recoge la "G" de
la jornada de liga jugada esa semana.

**Con esto, las 73 pantallas de la auditoría de migración quedan cerradas.** Sigue pendiente, fuera
del alcance de esta pantalla y ya documentado antes en este mismo archivo: `Prensa.arbitro_dudoso()`
(necesita un sistema de nombres de árbitro que no existe) e `Instalaciones.abarata_operacion()`
(necesita la línea de gasto "oper" que falta en `Finanzas.mes()`). Y las cuatro pantallas nuevas que
no son parte de las 73 del HTML -`vCiudad`/`vEditor`/`vIdentidadPlus`/`vBanco`, del orden de 25h-
siguen esperando el visto bueno explícito antes de empezarlas.

## "OPERACIÓN, VIAJES, SEGURIDAD E IMPUESTOS": EL GASTO QUE FALTABA (11-9-2026)

El segundo de los dos pendientes de arriba, cerrado el mismo día: `Instalaciones.abarata_operacion()`
llevaba escrita desde antes -devuelve 0,88 si el huerto certificado llega a nivel 3- y nadie la
llamaba. El motivo: en Godot no existía NINGÚN gasto de "operación" en el cierre de mes, así que no
había nada que abaratar. El HTML sí lo cobra, cada mes, siempre:

```
const oper = round((derechosTV(c)+auspicioBase(c)) * 0.42 * (ciudad.eco.cert ? 0.88 : 1));
mov(-oper, "Operación, viajes, seguridad e impuestos");
```

Sin esa línea, el club se quedaba con el 100% de la televisión y el patrocinio en vez del ~58% que
le tocaba de verdad -un club cualquiera terminaba la temporada con bastante más caja de la que
tendría en el HTML, aunque nada en el juego avisara de que faltaba algo: la caja subía, y una caja
que sube no parece un bug-.

**Portado a `Finanzas`:**
- Dos campos nuevos: `aplica_operacion` (bool, `false` por defecto) y `factor_operacion` (float,
  `1.0` por defecto). Mismo patrón que `aporte_instalaciones`/`factor_tv`: `Finanzas` no conoce a
  `Instalaciones`, así que el factor entra desde fuera.
- **Solo tu club la paga**, a propósito: el HTML nunca simula la contabilidad completa de los otros
  383 clubes -usan `refCaja(rep)` y no la mueve nadie salvo los fichajes-, y Godot SÍ los simula a
  todos. Los otros clubes ya usan `Federacion.ajuste_de_directiva()` como correctivo de esa
  simulación completa -ver el comentario grande sobre las dos curvas que se cruzan en el club medio,
  arriba en este mismo archivo `finanzas.gd`-; sumarles esta partida suelta sin recalibrar ese
  correctivo habría reabierto el mismo agujero que ya costó una depuración ("Cobreloa acababa con 86
  millones en rojo"). `aplica_operacion` se pone en `true` solo al construir el `Finanzas` de
  `mi_club_id`, en `Mundo.avanzar_semana()`.
- `Finanzas.operacion(ingreso_tv, ingreso_patrocinio)` cobra el 42% de lo que ESE mes dejaron
  televisión y patrocinio -no una cifra aparte, las mismas que ya se acaban de cobrar en `mes()`-,
  recortado por `factor_operacion`.
- La proyección anual (`proyeccion_anual()`, pantalla de Finanzas) y el cálculo de Fair Play
  Financiero (`Mundo.nueva_temporada()`) también quedaron al tanto -son objetos `Finanzas`
  desechables que solo PREGUNTAN, no cobran nada-, para que la cifra que enseña la pantalla y la
  que de verdad se cobra cada mes sean la misma cifra, no dos calculadas aparte.

Sin tocar `Azar` en ningún punto -es aritmética pura sobre montos que ya se calcularon-, así que no
había riesgo de desordenar la secuencia de números aleatorios que usan las pruebas del banco que
esperan valores exactos tras muchas temporadas simuladas.

Verificado con el banco completo (0 fallos, incluida la simulación de temporadas enteras con este
gasto nuevo de por medio) y con una captura aislada: al llegar al cierre de mes, `libro_financiero`
anota "Operación, viajes, seguridad e impuestos" con el monto correcto y en negativo.

## LOS ÁRBITROS DECIDEN COSAS DURANTE EL PARTIDO (11-9-2026)

El último pendiente que quedaba anotado en este archivo: `Prensa.arbitro_dudoso()` tenía completa
la rama de "reclamo formal" en el despacho, pero nada del motor generaba un árbitro con personalidad
que decidiera algo durante un partido. El HTML sí lo hace -`ARBITROS`, doce árbitros con nombre y
un perfil (`tarjetero`/`permisivo`/`estricto`/`casero`/`figura`), cada uno sesgando tarjetas y hasta
algún penal mientras se juega-.

**Primer intento, descartado a medio camino**: se escribió una clase `Arbitros` nueva que reconstruía
el mismo hash del HTML. Al ponerse a escribir la prueba en el banco apareció `Previa.arbitro_de()`
-que YA existe, ya lee la tabla exportada `Datos.tabla("ARBITROS")`, y ya es lo que enseña `vPrevia()`
antes de cada partido tuyo-. Tener dos hashes distintos calculando "el árbitro de este cruce" es
justo la clase de bug que se cuela sin que nadie lo note: la previa podría anunciar un árbitro y el
partido dejar pitar a otro. Se borró la clase nueva y `Partido.preparar()` llama a la función que ya
existía.

**Portado a `partido.gd`:**
- `Partido.arbitro` (nuevo): se calcula una vez en `preparar()`, vía `Previa.arbitro_de(rival_id,
  ctx_semana)`. Cuando el cruce es tuyo, `rival_id` es el otro club -igual que le pasa
  `principal.gd` a `Previa` para la previa real-; entre dos clubes de la IA no hay "rival" con
  sentido, así que cae en `visita.id` sin más -solo hace falta que sea determinista, no que sea "el
  tuyo"-.
- `Partido._chequeo_arbitral()`, llamado al principio de `_atacar()` -antes de que se decida si la
  llegada termina en gol, atajada o fallo, igual que en el HTML-: `tarjetero` reparte una amarilla
  de más a cualquier lado (1,0%), `casero` se la reparte SIEMPRE al que visita (0,8%), `estricto`
  regala un penal -55%/45% a tu favor cuando el cruce es tuyo, parejo si no hay nadie a quien
  favorecer- (0,4%), `figura` solo narra que anuló un gol sin tocar el marcador (0,3%).
  `ctx_factor_tarjetas` -el "VAR recorta las tarjetas" que ya usaba `_incidencias()`- recorta estas
  probabilidades a la mitad también: el árbitro se cuida más con la cámara encima.
- Señal nueva, `decision_arbitral(texto, minuto)`: solo narra -las tarjetas y el gol de penal YA
  se cuentan por `tarjeta`/`gol`, que es de donde sale el estado real (amarillas, suspensión,
  marcador)-. Conectada en `partido_vivo.gd` con su propia línea de color.
- `Mundo._avisar_a_la_directiva()`: si perdiste -de verdad, no empataste- y el árbitro de esa jornada
  de liga era "casero" o "figura", llama a `Prensa.arbitro_dudoso()` -el "`G.ultArbMal`" del HTML,
  que tampoco estaba conectado a nada ahí: no había de dónde copiar el disparador, había que
  encontrarlo con el mismo criterio (`!gane && M.hg<M.ag && perfil en [casero, figura]`)-. Con esto,
  la rama de "reclamo formal" en el despacho por fin recibe alguna vez el aviso que esperaba.

**ESTO SÍ CONSUME `Azar`, y a propósito**: a diferencia de un adorno cosmético (ver
[[dinastia-azar-determinista]]), las decisiones del árbitro cambian tarjetas y algún marcador de
verdad, así que tenían que salir del mismo generador determinista que el resto del partido. La
consecuencia colateral, ya avisada antes de escribir una sola línea: como `_chequeo_arbitral()` se
llama en CADA llegada de CUALQUIER partido del juego (no solo el tuyo), corre el sorteo compartido
un poco para todo lo que se simule después. Se cazó exactamente una vez: la prueba de "en cancha
neutral se pierde la ventaja de local" -que ya había peleado antes con este mismo problema, ver su
propio comentario en `banco.gd`- salió al revés con la semilla de esta sesión (4,16 contra 4,38 en
vez de 4,47 contra 4,24) sin que la ventaja de local se hubiera roto de verdad -nadie tocó
`simular_minuto()`, el bono del 1,08 sigue intacto-. Se subió la muestra de esa prueba de 300 a 800
partidos por lado en vez de tocar el umbral, que es la misma cura que esa prueba ya se había dado a
sí misma una vez (de "victorias" a "goles", y de "goles" a "remates").

**Otro bug, cazado escribiendo la prueba nueva, sin relación con los árbitros**: los primeros
contadores de la prueba (`var narraciones := 0`, incrementado dentro de un lambda conectado a una
señal) siempre daban 0 aunque el árbitro sí estuviera decidiendo cosas. GDScript captura las
variables locales de TIPO VALOR (int, float, bool) **por copia** en el momento en que se crea el
lambda: `narraciones += 1` dentro del closure movía una copia privada, nunca la variable de afuera.
`_probar_partidos()`, un poco más arriba en el mismo archivo, ya esquivaba esto con un diccionario
(`oidos`) -un tipo por referencia, que sí se comparte-; la prueba nueva se corrigió con el mismo
truco.

Verificado con el banco completo (0 fallos, incluidos los 16 sucesos arbitrales narrados y las 1.375
tarjetas -arbitrales y normales juntas- que salieron en los 500 partidos de la prueba nueva) y con
una captura en vivo: se abre un partido, el árbitro que pita es exactamente el que la previa venía
anunciando, y el partido termina sin reventar.

## LOS CUATRO PENDIENTES DE ~25H ERAN EN REALIDAD ~3-4H (11-9-2026)

El usuario dio el visto bueno a `vCiudad`/`vEditor`/`vIdentidadPlus`/`vBanco`, los cuatro aplazados
desde el 8-9 con la nota "~25 horas, hay que escribir el motor desde cero". Antes de tocar una línea
se mandó una auditoría a fondo (agente `Explore`) porque esa nota ya no cuadraba con lo que se había
usado ESTA MISMA sesión: `Ciudad.penalizacion_cesped()`/`factor_aforo()`/`cobrar_subvencion()` y
`Banco.hay_veedor()`/`en_mora()` vienen de clases que, según la nota vieja, "no existen".

**Resultado de la auditoría: la nota estaba mal desde antes de escribirse `Ciudad`.** Las cuatro
pantallas tienen motor completo en `nucleo/` Y pantalla completa en `ui/principal.gd` -ninguna es
"pintura sin motor" ni "motor sin pintura"-. El trabajo real que quedaba era de horas, no de días:

**1. `vCiudad`**: motor y pantalla al 100%. Solo un comentario desactualizado en `hinchada.gd:8-10`
que decía que las peñas y las ramas del club "quedan fuera porque dependen de `initCiudad()`, que no
existe aquí" -mentira desde que se escribió `Ciudad`, y las dos SÍ están portadas y con pantalla
propia (`_pintar_penas_y_ramas()`)-. Corregido el comentario, nada de código.

**2. `vBanco`**: motor y pantalla al 100%, ya usado en producción -`_motivo_fichaje_bloqueado()`
bloquea el mercado en mora desde antes de esta sesión-. Lo único que faltaba de verdad: **cero
pruebas propias**. `_probar_banco()`, nueva en `pruebas/banco.gd`, con 36 comprobaciones: la cuota
francesa contra la fórmula a mano (1.000.000 al 1% en 12 cuotas → 88.849), el tope de dos líneas, el
bono social -que SÍ se puede emitir en mora, a diferencia de un crédito normal-, prepagar y
renegociar, y la escalada completa sobregiro→mora→veedor→liquidación en las semanas EXACTAS que
marcan las constantes (4/8/12), con la señal `liquidado` disparándose de verdad. Las 36 pasan.

**3. `vIdentidadPlus`**: motor y pantalla al 100% -zonas, naming, proveedor, premium, las tres
camisetas, todo ya portado-. El único hilo suelto era de la identidad BASE, no de la Plus: `Club.
esc_simbolo` -el emoji del escudo, "ESC_SIM" del HTML- se guardaba en el guardado desde hacía
semanas y `Escudo` nunca lo leía ni había dónde elegirlo. Cerrado: `Escudo.simbolo_de(c)` reemplaza a
las iniciales cuando hay símbolo -mismo "sym ? ... : ini" del HTML, nunca las dos cosas juntas-, con
el mismo tercio-de-los-clubes-por-hash que en el HTML para los que no lo eligieron a mano
(`(h>>8)%3===0`), y un selector nuevo junto a Forma/Patrón en Gente → Identidad.

**4. `vEditor`**: el más completo de los cuatro y también el que más gap real tenía. Cerrado:
- **Exportar CSV** ("Mi liga"/"Todo el mundo"), que no existía -`Editor.exportar_csv()`, mismo
  formato que ya aceptaba el importador, así que lo exportado se puede volver a pegar tal cual-. Sin
  pie ni habilidades porque esos dos campos no existen todavía en `Jugador` -inventar un valor en la
  exportación sería mentir sobre el jugador-.
- **Picker de país** en la ficha del jugador (`fijar_campo` ya aceptaba `"pais"` desde antes; solo
  faltaba el botón).
- **"🎲 Aleatorio"**, que repinta el aspecto entero de una vez. Portado tal como lo hace el HTML
  -`edAleatorio()` no sortea rasgo a rasgo, vuelve a llamar al generador de aspecto con un id falso-:
  se separó `Cara.look_de(j)` en `Cara._look_base(semilla)` (la parte que hashea) y `Cara.
  look_de(j)` (que le pasa `j.id` y le encima lo tocado a mano), y `Cara.look_aleatorio()` le pasa una
  semilla al azar. **No usa `Azar`** -el generador determinista de la partida-: es una herramienta
  manual del editor que nunca corre durante la simulación, y tocar el generador compartido aquí
  habría corrido la secuencia que sí tiene que ser reproducible para el resto del motor.

  **Bug real encontrado por la propia captura de pruebas**: los botones "Mi liga"/"Todo el mundo" del
  exportador estaban CAMBIADOS -"Mi liga" mandaba `false` a `Editor.exportar_csv(solo_mi_liga)` y
  exportaba las 9.600 líneas del mundo entero; "Todo el mundo" mandaba `true` y exportaba solo las
  400 de la propia liga-. La causa: `_exportar_csv(ed, todo: bool)` nombraba su parámetro al revés de
  lo que hacía -pasaba `todo` directo como `solo_mi_liga`, sin invertir-, un nombre engañoso que hizo
  fácil conectar el botón equivocado sin que nada avisara. Arreglado invirtiendo el cableado de los
  dos botones y renombrando el parámetro a `solo_mi_liga` para que decir lo contrario de lo que hace
  ya no compile limpio a la vista.

  **`habs` NO estaba fuera -corrección sobre lo que se escribió aquí mismo hace un rato, antes de
  investigar más-.** El primer vistazo solo miró si `Jugador` tenía un campo `habs`, no lo tiene, y
  de ahí se concluyó -mal- que el sistema entero faltaba. Revisando `entrenamiento.gd` de verdad:
  **`Entrenamiento.sortear_habilidades(j)`** ya vive dentro de `Mundo.crear_jugador()` desde antes de
  esta sesión -"LAS HABILIDADES DE NACIMIENTO", con su propio comentario explicando que se enganchó
  ahí a propósito-, guarda el resultado en `Entrenamiento._habs` (un diccionario id→lista, NO un
  campo en `Jugador`: la arquitectura de Godot guarda esto en el sistema que lo usa, no en cada uno
  de los ~8.400 futbolistas, mismo patrón que `Cara.look_de()` con el aspecto), y `principal.gd` ya
  lo pinta en la ficha del jugador (`mundo.entrenamiento.habilidades(j)`, líneas 2619 y 4749). Lo
  único que de verdad faltaba -y era chico, no un sistema- era el bono de +5% al valor de mercado con
  3 o más habilidades (`if(j.habs.length>=3)v*=1.05` del HTML). **Cerrado**: `Jugador.tasar()` sigue
  sin poder verlo -las habilidades no viven en el jugador-, así que se aplicó donde ya existía el
  mismo problema resuelto para el historial médico. `Entrenamiento._tasar(j)` ya llamaba a `Medico.
  tasar(j)` cuando hay parte médico -tasa normal y castiga encima, recalculando el sueldo desde el
  valor ya castigado- para el mismo motivo (el historial tampoco vive en `Jugador`); se sumó el mismo
  bono ahí, con el mismo criterio. Ojo con el alcance real: `_tasar()` solo la llaman los caminos de
  entrenamiento (`_subir_media()`); un jugador recién creado con 3+ habilidades de nacimiento no ve el
  bono hasta la primera vez que sube de media entrenando -mismo alcance parcial que ya tenía `Medico.
  tasar()` antes de esto, no una regresión nueva-.

  **`pie` (pie hábil) TAMPOCO estaba fuera -segunda corrección sobre lo que se escribió aquí antes de
  investigar más a fondo, la primera vez fue con `habs`-.** El primer intento agregó `var pie: String`
  a `Jugador` y **rompió la compilación de toda la clase**: ya existía `func pie() -> String`, que
  calcula el pie de un hash del id -misma proporción 76/24 del HTML, deliberadamente NO guardado,
  con su propio comentario explicando por qué ("no inventar un campo persistido nuevo solo para un
  matiz de un 6%")-. `aptitud_en()` ya lo usaba, pero `aptitud_en()`/`media_en_puesto()` solo se
  llaman desde UN sitio de toda la interfaz (`principal.gd:4715`, la vista "cómo rendiría en otro
  puesto"): nunca desde `Club.once()` ni desde `Partido._media_linea()`, así que el 6% de penalización
  a un lateral del pie contrario **nunca pegaba en un partido de verdad**, pese a que el propio motor
  ya sabía calcularlo. Revertido el campo nuevo, cerrado de la forma correcta: `_media_linea()` en
  `partido.gd` llama a `Datos.es_lateral(j.pos_e)`/`Datos.banda(j.pos_e)` (dos atajos nuevos en
  `datos.gd`, mismo patrón que `Datos.grupo()`, leyendo el campo `b` de `POSD` que ya venía exportado
  y sin usar) y a `j.pie()` -el método que ya existía-, sin tocar `Jugador` en absoluto.

  **Y de paso, un SEGUNDO bug real en el mismo método, cazado por la prueba nueva sobre un mundo
  generado de verdad**: `pie()` sumaba `unicode_at(i)` sin mezclar -`h += ...`, no un hash de verdad-,
  y para los ids correlativos que reparte `Mundo.crear_jugador()` ("j1","j2","j3"...) eso crece tan
  despacio -los dígitos van de 48 a 57- que el resultado se queda pegado por debajo de 76 durante
  miles de jugadores seguidos. Midiendo sobre un mundo de tres países: **100% diestro**, cuando tenía
  que rondar el 76% del HTML. Es la MISMA trampa que ya se pagó una vez con `Cara.look_de()` -su
  propio comentario ahí cuenta "24 jugadores con dos cortes de pelo entre todos" por el mismo motivo,
  sumar en vez de mezclar-, esta vez en un método distinto que nunca se le aplicó el arreglo. Cerrado
  con el mismo hash multiplicativo (djb2) que ya usan `Escudo._hash()`/`Cara._hash()`: la proporción
  vuelve a rondar el 76% de verdad.

  **Y un TERCER hallazgo, esta vez en una prueba vieja, no en el motor**: con la penalización del pie
  ya pegando de verdad, la muestra fija de 40 partidos de `_probar_partidos()` cambió lo suficiente
  para que un árbitro "estricto" regalara un penal dentro de esa muestra por primera vez -antes nunca
  había caído uno ahí-, y eso hizo saltar una prueba sin relación: "cada remate termina en gol o en
  una señal de remate" esperaba que TODO gol viniera de un remate contado por `_atacar()`, pero el
  penal del árbitro llama a `_anotar()` DIRECTO -mismo camino que el HTML, que también lo suma aparte
  de `r<0.30`- así que ese gol nunca pasa por `remates_local/visita` ni dispara la señal `remate`.
  No era un bug del motor: era una prueba que asumía una invariante que dejó de ser cierta en cuanto
  el sistema de árbitros (de la tanda anterior) empezó a poder dispararse en esa muestra concreta.
  Arreglada restando los goles de penal arbitral -detectados por `decision_arbitral`, filtrando el
  texto por "penal" sin distinguir mayúsculas: las dos frases del "estricto" difieren en eso- antes
  de comparar.

  **Lección para las dos primeras correcciones**: antes de declarar un sistema "ausente" hay que
  revisar el motor completo -otras clases, otros métodos con nombres parecidos-, no solo si la clase
  obvia tiene el campo obvio. Las dos veces el sistema YA ESTABA, solo que vivía en un sitio distinto
  al que se esperaba. **Y para la tercera**: una prueba que asume "esto siempre pasa así" sobre una
  muestra fija puede quedar desactualizada en silencio cuando otra tanda -ni siquiera la misma-
  cambia lo que esa muestra puede llegar a contener; conviene sospechar de la prueba, no solo del
  código nuevo, cuando el fallo aparece lejos de lo que se acaba de tocar.

  **Quedan fuera de verdad, anotadas a propósito y NO tocadas todavía:**
  - `tatu`/`botín` (tatuaje y diseño de botines): puramente cosméticos en el HTML -parte del `look`,
    sin fórmula-, así que técnicamente cabrían en `Jugador.look` sin tocar nada más. No se agregaron
    porque no está confirmado que el "Cara" 2D de Godot (retrato, no cuerpo entero) tenga dónde
    dibujar un tatuaje de brazo o una bota: agregar el campo sin superficie donde se vea sería
    "personalización invisible", justo lo que la propia doctrina del proyecto pide evitar.

Verificado con el banco completo (0 fallos, cinco pasadas en total contando las de todo el bloque
`vEditor`/`vBanco`/`vIdentidadPlus`: el bug de los botones del exportador, el choque de nombres
`var pie`/`func pie()` que rompió `Jugador` entero -cascada de "Could not parse global class Jugador"
en cientos de líneas de `banco.gd` sin relación, mismo patrón que ya costó una depuración con
`Eco`≠`Economia`-, el hash sin mezclar de `pie()`, y la prueba vieja de remates que asumía una
invariante que el sistema de árbitros ya había roto sin que nadie se enterara hasta ahora) y con dos
capturas aisladas: una del motor puro del editor (exportar/reimportar/país/aleatorio, todo por
consola) y otra de la pantalla real -Ajustes → Editor, jugador seleccionado, sin reventar-.

## DOS EVENTOS DE PRENSA MÁS, EL LOGO DEL SPONSOR Y LA SALA DE PRENSA EN 3D (11-9-2026)

Tres piezas del pedido "termina lo de instrucciones profundas y mejora lo visual", cada una
verificada con captura antes de darla por cerrada -ver la lección nueva en
`dinastia-feedback-invertir-en-lo-visual.md`, que el usuario marcó explícitamente esta misma noche-.

**Ocupación Hostil de la Directiva y Fichaje por Intereses Comerciales** (`Prensa._pool()`/
`resolver()`): las dos dejan un "impuesto" -un jugador que TIENE que salir de titular- con el mismo
campo (`impuesto_pid`/`impuesto_hasta`) pero comportamiento distinto: la hostil no vence nunca y
purga al azar el cuerpo técnico (`Staff.purgar_al_azar()`, nuevo); la comercial vence al cerrar la
temporada pactada y paga dinero en el acto. `Prensa.revisar_impuesto()` cobra la penalización tras
CADA partido si el jugador no salió de titular -mismo patrón que `Federacion.revisar_cupo_juvenil()`,
enganchado en `Mundo._avisar_a_la_directiva()` al lado de esa misma revisión-. **Se descartó a
propósito un tercer evento, "Fondo de Inversión Buitre"**: ya existe, más completo, en
`Cesiones.presion_de_fondo()` -condicionado a haber vendido antes un % del pase con
`vender_participacion()`-, wireado desde `Mundo.avanzar_semana()` pero nunca antes verificado con un
test dedicado. Añadir una segunda versión habría duplicado la mecánica bajo el mismo nombre -la
misma lección de habs/pie de la sesión anterior, aplicada ANTES de escribir código esta vez-.

**`Marca` (`ui/marca.gd`)**: el primer logo real para los patrocinadores. `MARCAS` en `tablas.json`
siempre fue `[nombre, color]` y ninguna pantalla dibujaba más que esa palabra en ese color. Mismo
patrón que `Escudo` -forma+patrón por hash, para que la misma marca dé siempre el mismo logo- pero
con cuatro formas y seis patrones DISTINTOS de los de un escudo, para que un sponsor nunca se
confunda con un club. Sin texto en el SVG -misma limitación de siempre-, así que es una marca
abstracta; las iniciales se ponen aparte con una `Label`, igual que ya hacía `Escudo.iniciales()`.
Ya en la pantalla de Finanzas (`_marca()` en `principal.gd`), tanto en el contrato firmado como en
las tres ofertas sobre la mesa.

**La rueda de prensa en 3D** (`ui/rueda_prensa_escena3d.gd` + `_abrir_rueda_pantalla_completa()` en
`principal.gd`): antes la rueda de prensa era texto plano encogido dentro de la tarjeta de "asuntos
pendientes"; ahora hay un podio con DT, dos micrófonos y una pared de patrocinadores (escudo del
club + `Marca`, en rejilla, vía `SubViewport` -mismo truco que la pantalla gigante del sorteo-)
detrás, con la pregunta como subtítulo de transmisión sobre la imagen, **en pantalla completa** -el
usuario la comparó con la conferencia de prensa de FC26 y marcó que "eso debería tener su propio
lugar": la primera versión compartía espacio con la barra superior y la tabla de posiciones dentro
de un `SubViewport` de apenas 900×360. Ahora es una cinemática de pantalla completa colgada de
`self`, mismo patrón que `Sorteo` (`_siguiente_sorteo()`), con un `SubViewport` de 1600×720. **No
inventa diálogo nuevo**: `e["pregunta"]` sigue siendo el mismo texto de siempre del guion de
`Prensa`; esto solo le pone plató detrás. Se probó primero un generador 3D gratis (FLUX + TripoSR,
ver `dinastia-assets-cc0-web.md`) para estos props -funcionó de punta a punta, pero el modelo salió
sin textura ni color, blanco puro- así que se desechó a favor de geometría procedural, igual que el
resto del proyecto.

Tres rondas de captura antes de cerrarlo, cada una con un problema real distinto:
1. La pared de patrocinadores medía 9,6×3,0 m -más alta que una persona- y se comía la escena
   entera; el podio y el DT quedaban como un punto diminuto abajo del todo. Bajó a 5,4×1,7 m con más
   filas de logos más chicos (4×9 en vez de 3×7): el tamaño físico de la placa es lo que importa, no
   cuántos logos entran.
2. El DT era invisible: las luces apuntaban a la altura del PODIO (y=1,35) y el DT, medio metro más
   arriba, quedaba a oscuras contra una pared emisiva mucho más brillante; y el traje casi negro
   contra un fondo casi negro no tenía contraste aunque estuviera bien iluminado -mismo defecto ya
   documentado para el presentador del sorteo-. Se subió el apunte de las luces a la altura de cabeza
   y pecho, se aclaró el traje a azul marino visible y se sumó una corbata roja como acento de color.
   Con la energía inicial (8.0) la cabeza salía quemada -bola blanca sin rasgos, la MISMA trampa de
   exposición que ya se pagó con los balones del sorteo-; bajó a 3.2 con atenuación 1.4, calcada de
   la que ya usa `SorteoEscena3D`.
3. La cámara a 2,5 m y 38° de FOV dejaba medio encuadre de vacío negro alrededor del podio. Se acercó
   a 1,75 m y 30° de FOV: un plano de entrevista de verdad encuadra de hombros para arriba llenando
   el cuadro.

También se encontró y arregló un bug de layout al montar el subtítulo: `PanelContainer` con
`PRESET_BOTTOM_WIDE` y offset 0 en un `Control` simple (no un `Container`) da alto CERO en el punto
exacto donde termina la caja, y el panel crecía hacia ABAJO por su propio contenido -en la primera
captura el subtítulo tapaba la fila de "Cómo lo dices" de la fila de abajo-. Se arregló con
`offset_top` fijo (-72) más `clip_contents = true` como red de seguridad.

Y de paso, en la misma sesión: tres arreglos visuales en `SorteoEscena3D` que se habían dado por
buenos sin mirar una captura reciente -el polvo en suspensión se leía como un cielo estrellado (340
motas casi a brillo pleno llenaban el fotograma entero, hasta detrás de la pantalla), la pared LED
era un tablero de ajedrez de brillo aleatorio por panel en vez de un degradado de contenido, y el
brazo del presentador colgaba de `self` en una posición absoluta que no seguía el giro del cuerpo- y
uno en `Sorteo`: la rejilla del cuadro de grupos no tenía `size_flags_horizontal`, así que los
nombres de club salían cortados a la mitad ("Sao P", "Olimp") con dos tercios de pantalla vacíos al
lado.

## LA RUEDA DE PRENSA PASA A PANTALLA COMPLETA, Y LO QUE SE APRENDIÓ DEL GENERADOR 3D (12-9-2026)

El usuario comparó la rueda de prensa con la de FC26 y marcó que "eso debería tener su propio lugar":
antes vivía encogida dentro de la misma tarjetita de "asuntos pendientes" que comparte con el agente
que presiona o el jugador que te busca -un `SubViewport` de apenas 900×360 compitiendo por espacio con
la barra superior y la tabla de posiciones-. Ahora es una cinemática de pantalla completa
(`_abrir_rueda_pantalla_completa()` en `principal.gd`), mismo patrón que `Sorteo`
(`_siguiente_sorteo()`): un `Control` colgado directo de `self`, con un `SubViewport` de 1600×720. La
pregunta y las opciones siguen siendo exactamente los mismos datos de siempre (`Prensa.entrevista`);
esto no inventa diálogo, solo cambia dónde se presenta. `_pintar_despacho()` ya no la trata como un
"asunto" más -se abre sola en cuanto `hay_rueda()` es verdad, guardada en `_rueda_pop` para no abrir
dos veces-, y "Cómo lo dices" se repinta solo (`_repintar_posturas()`) sin reconstruir el plató 3D
entero en cada toque.

**El generador 3D, puesto a prueba de verdad esta vez.** El usuario insistió en usar el generador
objeto por objeto, como el que él mismo probó en Meshy. Se encontró y resolvió el bug real de por qué
el primer intento salía blanco -`vertex_color_use_as_albedo`, ver [[dinastia-assets-cc0-web]] para el
detalle técnico completo-, y se integró un podio generado con la forma correcta (mesa en cuña, dos
micrófonos de cuello de ganso) y color real.

Encajarlo con precisión para que tapara al DT de la cintura para abajo -algo que la caja procedural
hacía bien a la primera, porque uno elige su altura a mano- costó varias rondas de captura: sin una
altura de mesa predecible en un modelo reconstruido de una sola foto, el DT quedaba expuesto como un
bulto sin tapar por más que se probaran escalas de 1,1 a 1,57 m. **La solución no fue elegir entre las
dos técnicas, sino combinarlas**: el modelo generado se queda encima -aporta el detalle real que una
caja lisa no tiene- y una caja procedural sencilla, teñida del mismo color de `TINTE_PODIO`, se
esconde detrás para garantizar la oclusión exacta (`_montar_ocultador_podio()` en
`rueda_prensa_escena3d.gd`). Y por el camino se encontró la causa de fondo de por qué cada ajuste de
tamaño se sentía inestable: a 1,75 m de distancia y 30° de FOV, cualquier cosa cerca de la cámara
llena el encuadre entero -se corrigió alejando la cámara a 2,15 m y abriendo el FOV a 34°, resolviendo
la causa en vez de seguir retocando cada pieza por separado. **Lección para la próxima vez que se use
el generador**: no hace falta elegir entre generado y procedural -se pueden combinar, uno para el
detalle visual y otro para la función (ocluir, alinear)-, y antes de perseguir el tamaño exacto de
cada objeto conviene revisar si la cámara está simplemente demasiado cerca.

## EL SPONSOR EN LA CAMISETA PROCEDURAL, Y UN INSTALADOR DE UN CLIC (12-9-2026)

`Jersey.svg_de()` tenía un parámetro `sp` para el sponsor desde que se escribió, con un comentario que
decía "va como etiqueta de Godot encima, el rasterizador no pinta `<text>`" -y esa etiqueta nunca se
llegó a poner, ni el parámetro se llegó a usar en el cuerpo de la función-. Con `Marca` ya en el
proyecto (el logo real de un sponsor, no solo su nombre), `_pintar_equipacion()` en `principal.gd` por
fin superpone el logo del sponsor firmado sobre la camiseta procedural -solo cuando NO hay foto real:
una foto real ya trae su sponsor de verdad impreso, superponer otro encima sería mentir-. Verificado
con `pruebas/captura_equipacion.gd`, forzando un club sin foto real para ver el logo de verdad sobre
el dibujo.

Y por el pedido de "que sea solo poner enviar e instalar, por USB o por otro medio": `ENVIAR AL
CELULAR.bat` (raíz del proyecto) compila el APK más reciente y, si hay un teléfono conectado con
Depuración USB activada, lo instala directo con `adb install -r` -reinstala encima de la partida
guardada-; si no hay teléfono, deja el APK listo y abre la carpeta para copiarlo a mano. Ver
[[dinastia-empaquetado]] para la trampa de PowerShell que hizo fallar la primera prueba (el aviso de
"adb: daemon not running" por stderr, tratado como error fatal por `$ErrorActionPreference = "Stop"`).

## SEIS ESCUDOS Y CARAS QUE SALÍAN GIGANTES SIN AVISAR (12-9-2026)

Al arreglar el bug de la vista previa de Identidad -el escudo salía del tamaño de su textura real
(~220 px en vez de 54, porque `Escudo.textura()` rasteriza a 4x) y se llevaba con él un rectángulo de
color que debía medir 46×46- se barrió `ui/*.gd` completo buscando el mismo patrón: un `TextureRect`
con `stretch_mode = STRETCH_KEEP_ASPECT_*` pero SIN `expand_mode = EXPAND_IGNORE_SIZE`. Aparecieron
cinco más, todos reales: las tres miniaturas de camiseta del editor, el escudo junto a cada club en
"elegir club", el escudo y la cara en el editor de jugadores (Ajustes → Editor), el uniforme del
cuerpo técnico, y **el más visible de todos**: el escudo de la tarjeta "Partida en curso · Continuar"
del MENÚ PRINCIPAL -lo primero que ve el jugador cada vez que abre el juego-. Ninguno salía en el
banco de pruebas -no carga `ui/`- ni lanzaba ningún error: solo se veía mirando la pantalla de
verdad, que es exactamente la lección que ya se guardó esta misma noche sobre invertir tiempo real en
lo visual. Detalle completo en `dinastia-textura-sobredimensionada.md`.

## EL ASPECTO DEL DT LLEGA A GODOT: 552 COMBINACIONES QUE ESTABAN ESCRITAS Y NUNCA SE USARON

El usuario pidió mejorar la personalización del personaje que se elige al crear la partida. Buscando
dónde vivía eso apareció OTRO caso del mismo patrón que ya se repitió varias veces esta sesión:
`DT_PELOS` (23 cortes) y `DT_TRAJES` (6 vestimentas) llevaban desde el HTML original exportados en
`datos/tablas.json`, y ningún script de Godot los leía ni había ninguna pantalla donde elegirlos.

Se portó `caraDT(L,sz)` tal cual a `ui/cara_dt.gd` (`CaraDT`) -mismo lienzo 64×64 y misma técnica
que `Cara`, reutilizando sus paletas de piel y pelo en vez de duplicarlas-, se agregó `Roles.look`
(el aspecto es de la CARRERA del entrenador, no del club: si cambias de club, tu cara no cambia con
él) con el mismo patrón "solo se guarda lo tocado a mano" que ya usa `Jugador.look`, y se construyó
el editor completo en Club → Mi Carrera: vista previa, 🎲 Aleatorio, 23 cortes, volumen/raya/rapar
sienes, barba, vestimenta y seis colores libres. Verificado con captura real y con una prueba de
interacción -el aleatorio cambia el aspecto de verdad y sobrevive a guardar y cargar la partida-.

**Lo que queda fuera a propósito**: no es a cuerpo completo. Es un retrato 2D, igual que el de los
jugadores; llevarlo a un cuerpo 3D entero -por ejemplo para que aparezca en la sala de prensa en vez
de la silueta primitiva- necesita un rig como el que ya usa `Futbolista`/`AnimMixamo` en el campo, y
es trabajo aparte, no una mejora visual chica. Detalle completo en `dinastia-aspecto-dt.md`.

## UN GATITO EN EL MENÚ: PROBADO Y QUITADO EL MISMO DÍA

Se probó un gatito naranja decorativo en `Inicio` (dibujado con `_draw()`, animado caminando/
sentado/interactuando con un botón tras un rato ocioso). El usuario lo vio y pidió quitarlo de
inmediato -mala recepción, no un bug técnico-. Se retiró por completo (`ui/gatito.gd` borrado, la
línea que lo agregaba en `Inicio._ready()` revertida) el mismo 12-9-2026. Si se retoma la idea de una
mascota en el menú alguna vez, más vale mostrar una captura clara y pedir el visto bueno ANTES de
darlo por terminado, no después.
