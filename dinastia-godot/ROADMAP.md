# RUTA DE DESARROLLO — DINASTÍA

## MODULARIZACIÓN DE `principal.gd` — CERRADA (25/26-9-2026): 15.589 → 14.640 líneas
Pedido explícito del usuario: reducir la fragilidad de un archivo monolítico del que depende todo
el juego -"15 mil líneas todas juntas una dependiente de otra es un gran riesgo". Cinco tandas,
cinco patrones distintos según el acoplamiento real de cada pantalla, todas verificadas con banco +
captura real pulsando botones de verdad, no solo mirando que pinten:
- [x] `ui/componentes/panel_mercado.gd` (`PanelMercado`) -componente de escena con estado propio
  (filtros, negociación activa)-.
- [x] `ui/componentes/tabla_competicion.gd` (`TablaCompeticion`) -clase estática, sin estado, para
  lo que solo "pinta datos" sin interacción propia-.
- [x] `ui/componentes/ficha_jugador_info.gd` (`FichaJugadorInfo`) -8 de las 14 funciones de la
  ficha del jugador: las de SOLO LECTURA (estadísticas, cabeza, promesa, habilidades, historial
  médico, vida personal, historial de crecimiento, informe ciego). Mismo patrón estático.
- [x] `ui/componentes/ficha_jugador_acciones.gd` (`FichaJugadorAcciones`) -las 5 funciones de la
  ficha que quedaban, con botones que mutan el mundo (desarrollo prioritario, reconversión, marca/
  fidelidad, similares, venta/rescisión). **No hizo falta el patrón de señales de `PanelMercado`
  que se estimaba aquí** (15-20 señales): al pintarse una sola vez por refresco de ficha, sin ciclo
  de vida propio, bastó una clase estática que recibe la acción como parámetro `Callable` -un
  tercer patrón, más liviano que señales para este caso concreto de "una sola pintada, no un nodo
  persistente"-. `principal.gd` sigue siendo dueño de la mutación real y se la pasa en un closure.
  Verificado pulsando los botones de verdad (`Button.pressed.emit()`), no solo mirando que pinten
  -la lección del bug crítico del mismo día-. De paso, la auditoría reveló y se borró
  `_responder_oferta()`, código muerto desde que `PanelMercado` se conectó por señal (reemplazada
  por `_responder_oferta_mercado`). `principal.gd`: 15.589 → 15.036 líneas en las tres tandas de
  hoy. Ver detalle en `LEEME.md`.
- [x] `ui/componentes/panel_finanzas.gd` (`PanelFinanzas`) -4 de las 5 funciones de la pestaña
  Finanzas: `pintar_balance_y_caja` (pura, sin botones), `pintar_auspicio`/`pintar_patrocinio`/
  `pintar_banco` (con `Callable`, mismo patrón que `FichaJugadorAcciones`). Confirmado con grep: eran
  531 líneas, más que el "~200 líneas" del plan externo -tercera vez que se repite esta
  subestimación-. `_pintar_finanzas` (precio de entrada, tienda, proyección anual, resumen, libro de
  movimientos) se queda en `principal.gd` como orquestador, igual que `_ver_ficha`. De paso se borró
  `_puesto_en_liga()`, otra función muerta -su único llamador era `_pintar_auspicio`, ya movido-.
  Verificado pulsando "Firmar" auspicio, lanzando una campaña y tomando un crédito de verdad, con un
  tropiezo real en la propia prueba (buscaba el botón de campaña por "contiene EUR" y encontraba el
  de la tienda del club) corregido antes de darla por buena. `principal.gd`: 15.036 → 14.707 líneas
  en esta tanda. Con las cuatro tandas de hoy: 15.589 → 14.707. Ver detalle en `LEEME.md`.
- [x] `ui/componentes/panel_plantel.gd` (`PanelPlantel`) -la pestaña "Mi plantel", la última de la
  lista. Aquí el tamaño SÍ era el esperado (67 líneas), pero apareció un acoplamiento nuevo: pintar
  una fila de jugador navega ella sola (abre ficha, cambia de pestaña) y el color de las cabeceras
  pasa por `_color_de_paleta()` -la traducción de TEMA, distinta de `_color_accesible()`/`_pal_*()`
  que usan los otros cuatro componentes-. Duplicar esas dos cosas habría creado una segunda fuente de
  verdad, así que se pasan como `Callable` -mismo espíritu que `FichaJugadorAcciones`, aplicado esta
  vez a pintar-y-navegar en vez de a mutar-. De paso, `COL_ACENTO` resultó ser `var` (cambia cada
  refresco al color del club), no `const` como los otros colores: se pasa como parámetro en vez de
  duplicarse mal. Verificado pulsando la cabecera NOMBRE (confirma que `_orden_plantel` cambia de
  verdad) y el nombre de un jugador (confirma que la navegación por `Callable` sigue abriendo su
  ficha). `principal.gd`: 14.707 → 14.640 líneas. **Con las cinco tandas de hoy: 15.589 → 14.640.**
  Ver detalle en `LEEME.md`.
- **LECCIÓN QUE SE REPITIÓ CUATRO VECES ESTA SESIÓN (mercado, ficha, finanzas, y de nuevo finanzas):
  un plan externo que no midió el código real siempre subestima el tamaño y el acoplamiento.** Antes
  de prometer una extracción, grep primero: cuántas funciones, cuántos botones, cuántos puntos de
  llamada de cada helper compartido. **Antes de cada extracción**: revisar si sus helpers
  (`_texto`/`_celda`/`_escudo`/`_dato`) dependen de estado de Principal más allá de colores -ya se
  encontró que `_texto()` aplica paleta + modo daltónico + escala de texto, que `_fila_jugador()`
  navega por su cuenta, y que `_color_de_paleta()` no es lo mismo que `_color_accesible()`-, para no
  repetir el hueco de coherencia visual del mercado.
- **CERRADA LA LISTA.** No queda ninguna pantalla grande de `principal.gd` sin medir ni sin decidir
  su patrón. Lo próximo, si el usuario lo pide, es repetir el mismo ejercicio sobre otros archivos
  grandes del proyecto (`stadium_builder.gd` 2.562 líneas, `mundo.gd` 2.555, `city_builder.gd` 2.543,
  `roles.gd` 1.959...), no ya sobre `principal.gd`.
- [x] **Red de seguridad estructural, cerrada**: `pruebas/banco.gd` ahora carga las tres escenas
  raíz (`inicio`/`eleccion_club`/`principal`) como primera prueba, así que un futuro archivo roto
  nunca más pasa desapercibido con "0 fallos". Ver `LEEME.md`, 25-9.

## NOTA URGENTE CERRADA (25-9-2026): `principal.gd` no compilaba, el juego no arrancaba
Código muerto del mercado viejo (`@deprecated`, nunca borrado) citaba una variable
(`_lista_mercado`) eliminada el día que se conectó `PanelMercado`. El banco no lo detectaba
porque no carga `principal.tscn`. Cerrado, verificado con arranque real + captura de la pestaña
Mercado + banco completo (0 fallos). Detalle en `LEEME.md`, primera sección. **Lección para la
próxima**: cuando se reemplaza una pantalla por un componente nuevo, borrar el código viejo EN EL
MISMO commit, no dejarlo "@deprecated hasta la siguiente tanda de limpieza" — ese código muerto es
justo lo que no cubre el banco headless.


Creado 14-9-2026, a pedido explícito del usuario: *"genera una ruta de desarrollo... para que puedas
trabajar de forma autónoma sin mi intervención porque tendrás todo bien establecido"*.

**Cómo usar este archivo (instrucciones para mí mismo, sesión futura):**
- Es el **plan hacia adelante**, ordenado por fases. `LEEME.md` sigue siendo el **historial** de lo ya
  hecho — este archivo no lo duplica, lo continúa.
- Trabajar las fases **en orden**, de arriba hacia abajo, salvo que el usuario pida otra cosa. Dentro
  de una fase, el orden de los puntos también es el de prioridad.
- Antes de empezar cualquier punto: **verificar contra el código actual, no fiarse de esta lista** —
  el patrón que más se ha repetido en este proyecto es "algo que sonaba pendiente ya estaba hecho".
  Grep primero, tocar código después.
- Al cerrar un punto: banco de pruebas (`herramientas\run_godot.ps1`) + una prueba nueva permanente en
  `pruebas\` si el hallazgo lo amerita, actualizar `LEEME.md` con la sección de la tanda, tachar aquí
  con `[x]`, y respaldo (`herramientas\respaldar.ps1`) al cerrar un lote.
- Criterio de "terminado" (no negociable, ver `dinastia-estandar-de-terminado` en memoria): se llega
  desde el menú Y se nota jugando. No basta con que la función exista.
- Si una fase entera se completa, dejar la marca de fecha y pasar a la siguiente sin preguntar —el
  usuario dio permiso permanente para encadenar tareas.
- **Reforzado el mismo 14-9-2026**: *"puedes trabajar completamente solo sin solicitarme absolutamente
  nada... trabajar sin molestar"*. Con este archivo en la mano, el listón para detenerse a preguntar es
  altísimo: prácticamente solo una operación irreversible que ni siquiera este mismo archivo anticipó
  (y el borrado permanente de archivos ni siquiera es algo que se pueda ejecutar directamente — ver
  Fase 0, se resuelve con un script de un clic, no preguntando).

---

## FASE 0 — Decisiones de una sola vez (antes de seguir)

### 0.1 El HTML original: ARCHIVADO — CERRADO (14-9-2026)
**Decisión (14-9-2026):** la migración está confirmada al 100% desde el 11-9 (73/73 pantallas) y ya
hubo dos auditorías totales (12-9, 14-9) sin nada grande perdido. El criterio que el propio usuario
fijó el 7-9 ("1. migrar, 2. auditar, 3. recién entonces borrar el HTML") está cumplido.

**Pero no se recomienda borrarlo, se recomienda ARCHIVARLO**, por dos razones concretas:
- **No libera espacio real**: el HTML + `js/` + `css/` pesan ~1,4 MB. Borrarlo no resuelve ningún
  problema de disco (el problema real de disco son los respaldos, ya resuelto con la regla de "un solo
  respaldo").
- **Se ha usado como referencia de verificación HOY MISMO**: el bug de "votar en la Federación estaba
  roto" se confirmó comparando contra `js/juego.js` línea por línea. Sin el original, esa clase de
  verificación se vuelve mucho más difícil -no hay forma de saber si un comportamiento raro del puerto
  es un bug de la migración o una fidelidad al original sin releer el JS-.

**Acción concreta**: mover `dinastia-futbol-manager base.html`, `js/`, `css/` a una carpeta
`archivo-html-original/` en la raíz del proyecto, con una nota (`LEEME-ARCHIVO.txt`) explicando que ya
no es el juego activo y por qué se conserva. Esto dijo el usuario que quiere -"deberíamos eliminar el
html no"-, y archivar cumple la intención (sacarlo de en medio) sin perder la red de seguridad.

**HALLAZGO QUE FRENA EL MOVIMIENTO FÍSICO (14-9-2026), hay que resolver esto primero**:
`JUGAR DINASTIA.exe` (`herramientas\Lanzador.cs`) y `JUGAR DINASTIA (nube).bat` -los dos accesos de un
clic en la raíz del proyecto- **todavía abren el HTML viejo**, no Godot. El segundo además sincroniza
con Google Drive antes de abrirlo (`rclone copy "dinastia:DINASTIA" .`). Si el usuario usa cualquiera
de los dos para "jugar", hoy mismo sigue abriendo la versión vieja sin que nada se lo avise. Antes de
archivar el HTML hay que:
1. Confirmar con el usuario cómo juega él de verdad hoy (¿`entregas\windows\DINASTIA.exe`? ¿otro
   camino?).
2. Reescribir `JUGAR DINASTIA (nube).bat` (y decidir si vale la pena arreglar el `.exe` o retirarlo)
   para que abra el build de Godot en vez del HTML -manteniendo la sincronización con Drive, que sigue
   siendo útil-.
3. Solo entonces mover el HTML/js/css sin dejar un lanzador roto apuntando a un archivo movido.
4. Actualizar además `herramientas\run_harness.ps1:20` (ruta hardcodeada al HTML) si se decide moverlo,
   para que `exportar_datos.js` -la herramienta que regenera `tablas.json` si el HTML cambiara- lo
   siga encontrando.

**[x] CERRADO (14-9-2026)**: el usuario confirmó que jugaba por PowerShell (no por los lanzadores
viejos, así que no venía jugando el HTML por error) y pidió arreglar los dos lanzadores. Hecho:
- `herramientas\Lanzador.cs` reescrito para abrir el PROYECTO de Godot directo
  (`Godot_v4.7.2-stable_win64.exe --path dinastia-godot`, sin ventana de consola) en vez del HTML, y
  recompilado a `JUGAR DINASTIA.exe` -verificado arrancando y matando el proceso, Godot sí abre-.
- `JUGAR DINASTIA (nube).bat` reescrito igual, conservando la sincronización con Drive (rclone) antes
  de abrir.
- `dinastia-futbol-manager base.html`, `js\`, `css\` movidos a `archivo-html-original\`, con una nota
  (`LEEME-ARCHIVO.txt`) explicando por qué se conservan y el detalle de que sus fotos de equipaciones
  no se ven si se abre directo desde ahí (rutas relativas a `recursos\`, que sigue en la raíz).
- `herramientas\run_harness.ps1:20` actualizado a la nueva ruta -sigue funcionando: escribe su copia
  de prueba en la raíz del proyecto, así que las rutas relativas del banco viejo no se rompen-.
- Banco de pruebas de Godot: 0 fallos, verificado después de mover todo.

### 0.2 Recompilar el build de entrega
Lo que hay en `entregas\` es del 8/10-9-2026 -antes de TODOS los arreglos de esta sesión (visor 3D
invisible, señales duplicadas, votar roto, Champions muda, etc.)-. Antes de dar cualquier cosa por
"lista para mostrar" hay que correr `herramientas\empaquetar.ps1` de nuevo. Barato, hacerlo apenas se
cierre la Fase 1.

---

## FASE 1 — Terminar de cerrar "conectores mudos" — CERRADA (14-9-2026)

Contexto: dos rondas de auditoría de `.connect(` ya habían cerrado 13 señales de Federación/Hinchada
(13/14-9) y 4 más en el resto de `nucleo/` (Champions/Libertadores, entrenamiento, vestuario, estadio
propio), las dos veces encontrando bugs reales grandes.

- [x] **Los ~250 `.connect(` de botones/pestañas en `ui/principal.gd`**: un agente los revisó los 315
  uno por uno (no solo muestreo) con un script que descarta automáticamente el patrón seguro ("nodo de
  Godot nuevo, creado en la misma función que lo conecta"). 251/315 son ese caso seguro; las 64
  restantes (`mundo.*` dentro de `_conectar_noticias()`/`_conectar_sorteos()`/`_conectar_mi_continental()`,
  más `liga`, `resized`, los popups) ya tenían su candado correcto -ninguna nueva encontrada-. Único
  ajuste: la nota de qué objetos "no se recrean" estaba mal -`prensa`, `selecciones` y `cantera` SÍ se
  recrean en `tomar_el_mando()` (`nucleo/mundo.gd:1633,1656,1657`), la lista correcta de los que NO se
  recrean es `federacion`, `estadio`, `cesiones`, `roles`, `mercado`, `eras`, `copa` y el propio `Mundo`.
- [x] Instancias que se resortean sin reconexión: el único caso real era el de Champions/Libertadores,
  ya cerrado en el lote anterior (`_conectar_sorteos()` ahora se llama también en `_nueva_temporada()`).
- [x] Confirmado (14-9): el "lobby institucional con árbitros" NO existe en el código -no es una
  falsa alarma, es un hueco real-. Pasa a la Fase 3 como contenido nuevo, no como conector.

**Veredicto**: no queda nada real por cerrar en esta veta. Fase cerrada del todo.

---

## FASE 2 — La piel 3D (la brecha más grande para "sentirse terminado")

Diagnóstico del 14-9-2026, jugando de verdad y no solo leyendo código: la interfaz 2D de gestión está
a nivel comercial (tablas, fichas, mercado, ficha de jugador). El 3D -partido, estadio, ciudad- todavía
se ve como boceto funcional. Esta es la fase que más notaría el usuario si se muestra el juego a
alguien de afuera.

- [x] **La rueda de prensa, primera pasada: CERRADO (14-9-2026).** El locutor sin rasgos se
  reemplazó por un `QuadMesh` con el retrato real de `CaraDT.textura()`, y luego se corrigió que
  siempre mostraba al jugador aunque el rol activo tuviera un DT empleado dando la rueda, y que el
  fondo mostraba marcas genéricas en vez de los escudos de tu liga. Detalle en `LEEME.md`, secciones
  "EL DT DE LA RUEDA DE PRENSA..." y "LA RUEDA DE PRENSA, SEGUNDA PASADA...". Verificado con captura
  real (incluido el caso "DT empleado") + prueba permanente + banco (0 fallos).
- [x] **La rueda de prensa, al nivel de producción del SORTEO: CERRADO (14-9-2026).** Sala completa
  (paredes + techo con truss), periodistas visibles (siluetas con luz de relleno propia, antes eran
  invisibles), y tres planos de cámara que cortan solos cada pocos segundos (de trabajo, general con
  FOV abierto a 58°, y lateral) -el FOV fijo no bastaba, tuvo que variar por plano también-. Balanceo
  mínimo añadido al retrato del DT para que no se lea como una foto fija en los planos alejados.
- [x] **El DT apoya las manos en el podio: CERRADO (14-9-2026).** Pedido explícito tras el gesto del
  sorteo ("invierte en eso"). Un antebrazo por lado, plano sobre la mesa -no en diagonal desde un
  hombro alto, que en el plano de cámara más cerrado quedaba pegado a la barbilla-, con vaivén mínimo
  independiente en cada mano. Detalle completo, con las dos vueltas que costó acertar la altura real
  del podio, en `LEEME.md`, sección "EL DT APOYA LAS MANOS EN EL PODIO". Verificado con captura real en
  los tres planos + banco (0 fallos).
- [ ] **El presentador del sorteo: EN PAUSA a pedido del usuario (14-9-2026).** Se llegó a reemplazar
  la silueta de cajas por el humanoide real (`Futbolista`/`AnimMixamo`/`Vestidor`) y a corregir un
  ángulo de cámara que hacía ver el brazo "estirado" -detalle en `LEEME.md`, sección "EL PRESENTADOR
  DEL SORTEO"-, pero el usuario avisó que dejó un modelo 3D propio ("un tipo con tarjeta") en su Drive
  y prefiere rehacer el presentador con ese modelo en vez de seguir vistiendo al futbolista de traje.
  Pendiente: recibir ese modelo (arrastrado al chat, o con el conector de Drive cargado desde el
  arranque de una sesión nueva) y remontar `_montar_presentador_modelo()` sobre él. El mismo modelo
  serviría también para el público, y hay un modelo de un gato aparte para que interactúe con el menú
  inicial -anotado, sin empezar.
- [x] **El estadio, cámara "Principal (TV)": CERRADO (14-9-2026).** No era falta de textura -era la
  cámara literalmente encima del techo de la tribuna en estadios de 1 nivel, viendo su cara inferior a
  bocajarro-. Diagnosticado con un raycast real (no a ojo) y arreglado con un `minf()` en
  `camera_rig.gd`. Detalle completo en `LEEME.md`, sección "EL BLOQUE GRIS DEL ESTADIO...". Verificado
  con banco + prueba de regresión nueva + captura visual real: el campo se ve entero, sin el bloque.
  **"Detrás del arco" revisada con el mismo método y TAMBIÉN corregida**: el margen de 0,375 m sí era
  insuficiente -el mismo raycast confirmó que rozaba el techo en el 5-15% superior del encuadre-, y
  resultó ser la causa real del "bloque negro" que `dinastia-estadio-hueco-y-tunel-negro` documentó el
  13-9 sin diagnosticar (no era el cielo nocturno). Mismo arreglo aplicado. Las dos cámaras quedan
  cubiertas por la misma prueba de regresión.
- [x] **El letrero "Polideportivo": FALSA ALARMA, verificada y descartada (14-9-2026).** La captura
  que hizo sospechar (`sdfgi_on.png`) viene de `captura_sdfgi.gd`, una prueba que fuerza la cámara a
  65 m de altura para otra cosa (probar SDFGI) -muy por debajo de los 110 m con los que la cámara
  arranca de verdad (`ciudad_vista.gd:34`)-. Con la cámara REAL se generó
  `pruebas/cartel_ciudad_camara_real.png` (nuevo): los 6 carteles del mapa ("Centro comercial",
  "Piscina olímpica", "Zona industrial", etc.) se ven pequeños, legibles y bien proporcionados a sus
  edificios. Nada que arreglar aquí -otra vez el patrón de "verificar antes de anunciar un bug".
- [x] **Barrido de capturas 3D existentes: hecho (14-9-2026), sin hallazgos nuevos.** Revisadas
  `partido3d_*.png` (22 jugadores en cancha, animación e uniformes correctos), `diagnostico_tv.png`,
  `pantalla_estadio_3d_abierto.png` (nocturno, graderío y luces bien) y `pantalla_oficina_dt_aislada.png`
  (primer plano deliberado de un modelo, no la vista normal del jugador) -nada anómalo-. No se revisó
  cada una de las 130+ capturas de `pruebas/`, pero la muestra de vistas 3D centrales del juego
  (partido, estadio, ciudad) no mostró ningún caso nuevo del mismo patrón (bloque gris/textura rota).
  Si en el futuro algo se ve raro en una captura nueva: aplicar el mismo método que resolvió el bloque
  gris del estadio -no asumir la causa a ojo, escribir un raycast o aislar la geometría antes de tocar
  código-.
- [x] **Nivel "FIFA" del partido 3D: CERRADO (15/16-9-2026), sin necesitar API.** La parte de arte
  generado (`dinastia-herramientas-3d-ia`) sigue bloqueada por presupuesto de API, pero la parte de
  código/geometría no lo estaba y se hizo entera: balón con física real de arco y rodadura
  (`visor/balon_3d.gd`), 9 cámaras incluyendo POV y Tercera Persona (`visor/camera_rig.gd`), control
  manual de jugador estilo FC 26 (`visor/control_partido.gd`), radar táctico 2D (`ui/radar_partido.gd`)
  y arcos/redes de detalle real (`visor/stadium_builder.gd`). Detalle completo y verificación en
  `LEEME.md`, sección "EL PARTIDO 3D AL NIVEL FIFA...".

---

## FASE 3 — Sistemas grandes confirmados como pendientes, ordenados por impacto

Fuente: `LEEME.md` (cola del 12-9) + `dinastia-archivos-profundos-vs-codigo` (corregida hoy: de 5
"huecos baratos" que parecían pendientes, 4 ya estaban hechos -pizarra táctica, guerra de agentes, lío
nocturno, adaptación cultural-; el que de verdad falta es el que sigue en la lista de abajo).

1. **El estadio por MÓDULOS** -desarmar/rearmar el recinto con piezas 3D independientes en vez de
   reformar el conjunto completo o elegir entre 8 estilos enteros-. Decisión de diseño ya tomada
   (16-9-2026): las tres lógicas a la vez -bandeja, componentes, tramo-, en ese orden. Plan
   completo en `C:\Users\Alumno\.claude\plans\smooth-soaring-micali.md`.
   - [x] **Bandeja (16-9-2026): CERRADA.** Cada una de las 4 tribunas con su propio patrón de
     butacas y techo. Detalle y verificación en `LEEME.md`, sección "EL ESTADIO POR MÓDULOS, FASE 1".
   - [x] **Componentes (16-9-2026): CERRADA.** Túnel, banquillos, banderines de córner, tejido de
     red y dónde va el escudo -catálogos que ya existían y ya se cobraban, conectados al visor 3D
     por primera vez. Detalle y verificación en `LEEME.md`, sección "...FASE 2".
   - [x] **Tramo (estilos mixtos dentro de una misma tribuna): CERRADA (22-9-2026).** El spike del
     18-9 confirmó que el corte se sostiene visualmente con `uv1_scale.y=1`; esta tanda diseñó y
     conectó la fase completa -13 claves nuevas en `EST_DEF`, `EstadioPropio._tramos_personalizados()`,
     wiring real en `StadiumBuilder.build()`, UI en Club → Estadio-. De paso se evitó reintroducir a
     propósito el bug de "estática de TV" del 21-9 (el spike nunca había pasado por ese arreglo) y
     se encontró/corrigió un bug real de verificación (`Comercial.color_balon(mundo.comercial.balon,
     ...)` con `comercial` Nil, presente también en `captura_bandejas.gd`/`captura_componentes.gd`
     desde el 16-9 -esas capturas tampoco mostraban nunca el estadio real-). Detalle completo y
     verificación (datos + visual) en `LEEME.md`, sección "EL ESTADIO POR MÓDULOS, FASE 3 DE 3:
     TRAMO — CERRADA DE PUNTA A PUNTA". **Las tres lógicas del punto 1 quedan cerradas.**
2. [x] **Extender el espionaje de entrenamientos rivales a información táctica: CERRADO (22-9-2026).**
   `_pintar_juegos_mentales()` ahora suma mentalidad/presión/línea del rival, leídas de `rival.tactica`
   -mismo candado que el once probable-. Decisión deliberada: NO se le dio personalidad táctica a la
   IA (eso tocaría el balance de cada partido de la liga, no es una decisión de pantalla) -por eso casi
   todo rival lee "Equilibrada/Media/Media" siempre, documentado y verificado en pantalla, no
   escondido-. De paso, un bug real grande: un `:=` indexando un Array sin tipar rompía la carga
   ENTERA de `ui/principal.gd` y el banco headless no lo veía (no carga esa escena). Detalle completo
   en `LEEME.md`, sección "ESPIONAJE TÁCTICO DEL RIVAL, EXTENDIDO".
3. [x] **Lobby institucional explícito con árbitros: CERRADO (26-9-2026).** Un evento más en
   `Prensa._pool()`/`resolver()` (`"lobby_arbitral"`), sin interfaz nueva -mismo camino genérico de
   `Principal._pintar_decision()`-. Aparece solo si `Federacion.enojo_arbitral > 0` -es la mitad
   PROACTIVA que faltaba, complemento de `"reclamo"` (reactiva, ya existía) y del contador que ya
   encarece las apelaciones en `Federacion.apelar()`-. Asistir cuesta plata y baja el enojo, con 30%
   de filtrarse (funa + confianza de directiva); declinar no cambia nada. Verificado por motor
   (aparece/no aparece según el contador, cobra y baja el enojo de verdad) y con captura real del
   aviso en pantalla. Ver `LEEME.md`.

   ### 2-bis. LA PANTALLA DEL ESTADIO Y LAS VALLAS LED: CERRADO (23-9-2026)
   Sesión de una sola misión pedida por el usuario. La pantalla gigante pasa de un `Label` "0 - 0"
   (que además se cortaba) a **seis paneles en rotación** -marcador estilo transmisión, estadísticas,
   goleadores del partido, tabla de posiciones, máximos goleadores y bienvenida- más un corte a
   "¡GOOOL!" a pantalla completa. Y las 54 vallas de color liso del perímetro pasan a ser **LED con
   marca de verdad** (el club, DINASTÍA y cuatro de las 38 marcas de `MARCAS`, por hash del club)
   que cambian solas en ola. Detalle completo, con los tres bugs reales y los tres bugs de
   verificación que salieron por el camino, en `LEEME.md`, sección del 23-9.
   **Cierra el punto pendiente que arrastraba `dinastia-ideas-pendientes`** ("pantalla del estadio
   con tabla/goleadores dinámicos").

   ### 2-ter. ARQUITECTURA DEL ESTADIO Y PÚBLICO: PRIMERA PASADA (23-9-2026)
   Una auditoría (con agente) de `visor/stadium_builder.gd` buscando el patrón "medida en metros
   fija que solo cuadra con UNA forma y UN número de niveles" encontró **12 casos**. Se cerraron los
   6 de más impacto visual: la grada veía solo el 17% de su textura (atlas de UV del `BoxMesh`,
   medido con `pruebas/diagnostico_uv_caja.gd`), el público estaba reclinado 58,6°, el público de la
   textura se sorteaba en posición libre (ahora va en filas con escalones y escaleras), 4 de las 10
   lámparas de la corona flotaban sobre el campo, el cubo colgante nunca quedaba bajo cubierta y las
   esquinas del cuenco sobresalían 3,5 m hacia la cancha. Verificado con `pruebas/captura_formas_
   estadio.gd` (nuevo), que fotografía **las seis formas y los tres niveles** -hasta hoy todas las
   capturas del proyecto se sacaban con el mismo estadio, y por eso nada de esto se veía nunca-.

   - [x] **Los 12 hallazgos de la auditoría: CERRADOS (23-9-2026).** Los 6 últimos en la tercera
     tanda del día: el túnel anclado a 64 m fijos y sus tipos "arco"/"foso" (el arco plantado dentro
     del área grande, "foso" entero bajo el césped opaco o sea invisible), los dos banquillos
     superpuestos (el viejo recibía `dx` y no lo usaba), las vallas LED cruzando el dugout, el
     escudo de tribuna con tres posiciones fijas, las dos cámaras del `CameraRig` -incluida una
     cuyo `clampf(alto*0.55, 12.0, 34.0)` **nunca superaba su propio mínimo**, o sea código muerto-
     y las cuatro esquinas que desaparecían en "herradura".
   - [x] **Telones de hinchada y vomitorios: HECHOS (23-9-2026).** `PlaneMesh` hijos del `deck` en
     coordenadas locales, para que la inclinación la resuelva el nodo.
   - [x] **La hinchada, viva: HECHO (23-9-2026).** `visor/hinchada.gdshader`: se balancean con fase
     propia, saltan de a poco, la cabeza va en tono de piel en vez del color de la camiseta, y las
     estaturas varían ±10%. Y el público 3D llega a la ÚLTIMA fila, no a media grada (pedido
     directo del usuario) -se logró separando el presupuesto de vértices de las butacas del de los
     hinchas: una butaca cuesta 988 vértices y un hincha 70-.

   ### 2-quinquies. BANDEJAS DE VERDAD, ESQUINAS EN DIAGONAL Y CONECTORES (23-9-2026, sesión final)
   Pedido: *"el estadio debe ser modular... más bandejas y variantes para cuando uno agrande el
   estadio (máximo 150.000)"*. Reescrito `StadiumBuilder.build()`: cada tribuna ahora es N bandejas
   reales (10 m de fondo, 33° de rake, 3 m de peto entre una y la siguiente), no una rampa única que
   a 3 niveles llegaba a 58,6°. `NIVELES_MAX` sube de 3 a 5 (alturas 8/17,5/27/36,5/**46 m**), y
   `EstadioPropio.niveles_maximos()` sigue el nivel de la obra "Tribunas" hasta el final en vez de
   cortarse en 3. Las esquinas dejaron de ser un cubo (atlas de UV al 17%, ver
   `reference-godot-boxmesh-uv` en memoria) y pasan a ser grada real en diagonal, con hinchada.
   Se cerraron además los 12 hallazgos de una segunda auditoría (cancha pintada 64×100 en vez de
   68×105 -arreglado-, techos de esquina con z-fighting, burbuja de banquillo opaca, líneas de cal
   sin sombra, técnica del catálogo que se cobraba y no dibujaba nada: **pista de atletismo**
   (480.000, el capítulo más caro) y **banderas de hinchada** (tifo/bufandas/banderines), ahora
   ambas con geometría real. `visor/stadium_builder.gd` no se re-verificó con el banco completo tras
   el último arreglo de tipos (`Array[Color]`) por quedarse sin cupo de la sesión -**correr
   `herramientas\run_godot.ps1` antes de dar esto por cerrado del todo**, aunque
   `captura_formas_estadio.gd` (las 6 formas, hasta 5 bandejas) pasó en 0 fallos.

   ### 2-sexies. PEDIDO EXPLÍCITO DEL USUARIO, SIN EMPEZAR: colores por sección
   *"El estadio sea modular significa poder cambiar colores por sección, arco, líneas, bandejas una
   por una, cesped, pantalla, faros, luces nocturnas, LED, bancas, gradas, asientos."* Hoy
   `asiento1`/`asiento2`/`asiento3` son globales (con la excepción parcial de "bandejas"/"tramos" por
   tribuna, ya conectada). Falta: color independiente por CADA bandeja de CADA tribuna (no solo el
   patrón), color de poste/red por separado del de línea, y paleta propia para focos/vallas/LED. Es
   trabajo de `nucleo/estadio_propio.gd` (nuevas claves en `EST_DEF` + UI de Club→Estadio) antes que
   de `visor/`.

   ### 2-septies. PEDIDO EXPLÍCITO DEL USUARIO, SIN EMPEZAR: túnel navegable
   *"La zona del túnel deben ser más reales, a futuro el estadio será navegable con el
   protagonista."* Hoy `_tunel()` es decorado (una mole con boca, sin interior). Si el jugador va a
   caminar por ahí algún día, el túnel necesita profundidad real (un pasillo con `CollisionShape3D`,
   no una caja hueca) — anotado para cuando se diseñe el modo "caminar por el estadio", no antes.

   ### 2-quater. LO SIGUIENTE PARA EL ESTADIO, sin empezar
   - [ ] **El graderío por bandejas de verdad.** El fondo de la tribuna es 11 m FIJOS en las tres
     alturas, así que con 3 niveles la rampa queda a **58,6°** -ninguna grada real pasa de ~35-.
     Hoy se disimula contrarrotando butacas y hinchas para que queden de pie (lo cual es correcto:
     van sobre escalones), pero la rampa en sí sigue siendo demasiado empinada. El arreglo de
     verdad es partir la tribuna en 2-3 bandejas con su propio fondo y un pasillo entre ellas, que
     además es lo que se ve en `ea_fc25_referencia.mp4`. Es trabajo de geometría real, no un ajuste.
   - [ ] **Modelos 3D para camarógrafos y guardias** (el usuario recordó que hay personajes 3D
     disponibles): hoy son cajas. Son ~6 figuras, no miles, así que aquí sí cabe un modelo real
     -a diferencia del público, que tiene que seguir siendo `MultiMesh` sí o sí-.
   - [ ] **Nombre del jugador flotando sobre cada futbolista** con su barra de estado, como en
     `ejemplo-partido.mp4` (Soccer Manager). Es lo único grande de ese video que no se ha portado.
4. [x] **Animaciones de lenguaje corporal en la banda / "efecto banquillo" visual: CERRADO
   (22-9-2026).** Hasta ahora la banda estaba vacía -ni un suplente en ningún partido-. Ahora hasta 7
   suplentes por equipo (`visor/player_spawner.gd::spawn_banca()`) de pie junto a su banquillo -no
   sentados adentro, decisión de alcance explicada en `LEEME.md`-, y el banquillo del equipo que
   anota festeja con la animación real de gol (`ui/estadio.gd::_banca_celebra()`) y vuelve solo a la
   calma a los 3s. Detalle completo y verificación (datos + 3 capturas reales del ciclo antes/
   festejo/vuelta) en `LEEME.md`, sección "EL BANQUILLO YA NO ESTÁ VACÍO".
5. [ ] **Modo Director de Cantera completo** (edades 10-16: alimentación, estudios) -hoy la cantera
   arranca directo a los 16-18 años-. El más grande de esta fase, requiere motor nuevo real.
6. [ ] **Juegos mentales en el túnel** antes de salir a la cancha -el más chico y menos definido, sin
   diseñar.

---

## FASE 4 — Lo que queda del listado de 750/300 ideas (más chico de lo que suena)

Fuente: `dinastia-pendientes` (última auditoría de ese listado, ~100 ideas de las 750 originales,
repartidas en 6 bloques). **Antes de escribir nada de esta fase: volver a cruzar contra el código
actual con un agente** -el patrón de "ya estaba hecho" se ha repetido tantas veces en este proyecto
que dar esta lista por vigente sin re-verificar sería el mismo error de siempre.

- [ ] **37/38 — Mercado avanzado y zonas grises**: guerra de ofertas, derechos de formación,
  superagente, fichaje impuesto por el dueño, apuestas, transparencia.
- [ ] **39/40 — Insolvencia y política interna**: renegociar deuda, resta de puntos, administrador
  externo, bonos de hinchas, tope salarial, refundación, cláusula de salida del DT. (Ojo: parte de
  esto puede solaparse con `Banco`, construido el 13/14-9 -revisar antes de reescribir.)
- [ ] **44/45 — Reglamento y federación fino**: historial por árbitro, cambios de reglas entre
  temporadas, criterios de desempate, playoffs de descenso, repechaje, corrupción federativa.
- [ ] **46 — Selecciones**: lista preliminar, conflicto club-selección (lo demás de este bloque ya
  está hecho según `dinastia-pendientes` v3.1).
- [ ] **47 — Competencias**: editor de campeonatos, sede de final fija. (Cabezas de serie y
  Apertura/Clausura ya existen.)
- [ ] **50 — Meta**: cromos, museo global, mundo heredado. (Nivel de perfil del gestor ya existe.)

---

## FASE 5 — Pedido explícitamente en espera (NO TOCAR sin permiso directo)

Estas dos las pidió el usuario **dejar anotadas y no implementar**, no están a medio hacer:

- [ ] **Divisas seleccionables** (hoy todo el juego dice "EUR" fijo).
- [ ] **La cara real 2D moldeada sobre el modelo 3D del jugador en el campo** (hoy son dos sistemas
  separados: retrato 2D y textura de cabeza del atlas 3D). Ya hay un plan técnico completo escrito en
  `LEEME.md` ("PEDIDO POR EL USUARIO, SIN HACER TODAVÍA", punto 3) para cuando se autorice.

---

## FASE 6 — Limpieza técnica de bajo valor (cuando sobre tiempo, nunca prioritario)

- [x] **7 funciones huérfanas en `entrenamiento.gd`: BORRADAS (26-9-2026)** -confirmado con grep
  (llamada directa y por `.call()` dinámico) en todo el proyecto antes de tocar nada: `subidas_de`,
  `dar_puntos`, `arbol_por_rama`, `rama_habilidad`, `minimo_habilidad`, `requisito_habilidad`,
  `dt_puede`. Ver `LEEME.md`.
- [x] **`visor/match_playback.gd::is_final()`: BORRADA (26-9-2026)**, mismo método de verificación.
- [x] **`principal.gd` ya no costaba de verdad: RESUELTO (25/26-9-2026)** con las cinco tandas de
  modularización de hoy (15.589 → 14.640 líneas). Ver la sección de arriba.

---

## Nota sobre "cosas nuevas que ya entré al juego" (mencionado por el usuario, 14-9-2026)

El usuario avisó que ha ido agregando contenido nuevo (ej. la ciudad mejorada) que puede no estar
reflejado del todo arriba. Antes de arrancar una fase grande (3 en adelante), vale la pena un barrido
rápido de `git log`-like -aquí no hay git, así que `Get-ChildItem -Recurse | Sort LastWriteTime` sobre
`nucleo/`+`ui/`+`visor/`- para ver qué se tocó recientemente y no esté ya anotado en `LEEME.md`.

---

## FASE 7 — Continuidad si el proyecto pasa a otra IA (ej. Google Antigravity)

Pedido explícito del usuario (14-9-2026): tener esto listo por si se le acaba la cuota de Claude y
necesita seguir con otro asistente mientras tanto. **Si estás leyendo esto porque eres esa otra IA:
bienvenido. Esta sección es para ti, autocontenida a propósito.**

### Lo primero que hay que entender: dónde vive el conocimiento de este proyecto

Todo lo que Claude sabe de este proyecto vive en DOS sitios, y solo uno de ellos viaja contigo:
1. **Dentro del proyecto** (lo que estás leyendo): `dinastia-godot/LEEME.md` (el historial completo,
   ~4000 líneas, ordenado con lo más reciente arriba) y este `ROADMAP.md` (el plan hacia adelante).
   **Esto SÍ lo tienes.**
2. **La memoria propia de Claude Code**, en una carpeta fuera del proyecto (`~/.claude/...`), con
   decenas de notas más pequeñas sobre preferencias del usuario, hallazgos puntuales y contexto de
   conversaciones pasadas. **Esto NO lo tienes, y no hay forma de que lo tengas.** Si algo de lo que
   sigue suena incompleto, es por eso — lee `LEEME.md` entero antes de asumir que algo no existe.

### Las reglas de oro (todas costaron tiempo real aprenderlas, no las repitas)

1. **"Portar, no reescribir."** El juego migró de un HTML/JavaScript monolítico (archivado en
   `archivo-html-original/`, ya NO es el juego activo) a este proyecto de Godot/GDScript. Las fórmulas
   de balance (economía, fichajes, partidos) se portaron TAL CUAL desde ese HTML — no se rediseñan
   porque "parecen raras", costó semanas de ajuste fino en su momento. Si dudas si un número o una
   condición es fiel al original, compáralo contra `archivo-html-original/js/juego.js` (o `vistas.js`
   para pantallas) antes de tocarlo.
2. **Verificar SIEMPRE con el banco de pruebas + una captura real, nunca solo "el código compila".**
   El patrón de bug más repetido en este proyecto es una función escrita y probada en aislado que
   nadie conectó a la interfaz — "quedó escrito" no es "quedó hecho". Comandos exactos más abajo.
3. **Antes de dar algo por "pendiente" o "faltante": grep primero.** Este proyecto tiene un historial
   largo de sistemas que "sonaban sin construir" y ya estaban hechos con otro nombre (pasó con la
   pizarra táctica, la guerra de agentes, el lío nocturno — los tres el mismo día, 14-9-2026). Nunca
   anunciar un hallazgo sin haber leído el código real primero.
4. **No silenciar stderr al probar código nuevo.** Si un script revienta a mitad de camino, Godot
   igual "termina" e imprime lo que haya antes del fallo — parece que todo salió bien y no fue así.
5. **Un solo respaldo activo**, no una pila de copias — ver Fase 0 / abajo, el disco de esta máquina
   es pequeño (SSD de 119 GB).
6. **El usuario es chileno.** Tutéalo, nunca voseo argentino ("vos", "tenés"). Español en todo.
7. **No asume que puedes ejecutar comandos de borrado permanente de archivos tú mismo** — si tu
   entorno sí puede, genial, pero confirma con el usuario antes igual: es la única clase de acción de
   esta lista que de verdad no tiene vuelta atrás sin un respaldo.

### Comandos que vas a necesitar (PowerShell, Windows)

```powershell
# Banco de pruebas headless (851+ comprobaciones, tarda ~2-3 min). SIEMPRE antes de dar algo por cerrado.
herramientas\run_godot.ps1 -Salida "herramientas\salida\mi_prueba.log"
# Revisa el .log Y el .err.txt del mismo nombre -el segundo es el stderr, nunca lo ignores-.

# Jugar de verdad (abre una ventana)
herramientas\run_godot.ps1 -Jugar

# Capturar una pantalla del juego jugando (deja pruebas/pantalla.png)
herramientas\run_godot.ps1 -Captura

# Si algo se queja de "Identifier X not declared" en cuarenta líneas seguidas:
herramientas\run_godot.ps1 -Reimportar

# Respaldo fechado (reemplaza al anterior, no se apila)
herramientas\respaldar.ps1 -Nombre "lo-que-sea-que-hiciste"
```

Para una verificación puntual de un hallazgo nuevo, el patrón que se usa en todo el proyecto es
escribir un script headless corto en `pruebas/nombre.gd` + su `.tscn` (ver cualquiera de los ya
escritos ahí como plantilla, por ejemplo `pruebas/captura_conectores_14_9.gd`) que instancia
`res://escenas/principal.tscn`, espera unos frames, y comprueba con `print("OK ...")`/`print("MAL
...")`. Se corre con `herramientas\run_godot.ps1 -Escena "res://pruebas/tu_script.tscn" -Salida
"herramientas\salida\tu_prueba.log"`.

### Estructura del proyecto, en una tabla

| Carpeta | Qué es |
|---|---|
| `dinastia-godot/nucleo/` | La lógica del juego (economía, partidos, plantillas...), sin interfaz |
| `dinastia-godot/ui/` | La interfaz — casi todo vive en `principal.gd` (15.000+ líneas, un archivo por diseño: cada función pinta una pantalla completa) |
| `dinastia-godot/visor/` | El 3D: estadio, ciudad, los 22 jugadores en cancha |
| `dinastia-godot/pruebas/` | El banco de pruebas (`banco.gd`) + capturas de verificación puntuales |
| `herramientas/` | Scripts de PowerShell (correr, empaquetar, respaldar) + el Godot portable |
| `archivo-html-original/` | El juego VIEJO, ya no activo, conservado como referencia de fórmulas |
| `respaldos/` | Copias fechadas completas — dejar solo la más reciente |

### Al terminar cualquier tanda de trabajo

Igual que se le pide a Claude: actualizar `LEEME.md` con una sección nueva (arriba del todo, con
fecha) describiendo qué se hizo y cómo se verificó, tachar el punto correspondiente en este
`ROADMAP.md` con `[x]`, y dejar un respaldo. Así, cuando el usuario vuelva a Claude (o a quien sea),
el trabajo queda legible sin tener que releer el chat.

---

Relacionado: `LEEME.md` (el historial completo), y en la memoria de Claude:
`dinastia-archivos-profundos-vs-codigo`, `dinastia-pendientes`, `dinastia-estandar-de-terminado`,
`dinastia-trabajo-autonomo`, `dinastia-feedback-invertir-en-lo-visual`.
