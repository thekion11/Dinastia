# Memoria del proyecto Dinastía (para Claude)

Se lee al empezar cada sesión. Corta a propósito (la memoria larga se borró el 24-10; sigue en el historial de git).
Índice de docs: `docs/00_INDICE.md`. Método: `docs/01_metodo/METODO.md`. TODO lo pendiente: `docs/PLAN_GENERAL.md` (antes «plan del lunes»).
Actualizar este archivo solo con reglas u órdenes vigentes nuevas. Lo completado se BORRA de los documentos (no se tacha).

## Reglas fijas
- Responder en español. Trabajar solo en la rama asignada; nada de PR salvo que se pida. Commit y push tras cada bloque.
- Sin identificadores de modelo en commits ni archivos. Keystore: contraseña NUNCA en el repo. Sin subidas NUEVAS a LFS
  (no tocar ni mover lo ya en LFS: los originales solo están en GitHub). `*.zip`, `.avi`, `.mp4` nunca al repo.
- Datos reales solo en `pack_real.json`; el resto con nombres ficticios y política ficticia. No atribuir religión ni
  romances a jugadores reales. Keystore, licencias, FPS, música y builds los maneja el dueño.
- Irreversible (borrar ramas, reescribir historia, force push) solo con orden explícita. NO tocar las ramas `borrar-*`,
  `respaldo-historia-2026-10-24` ni `entregas/`, `marca/`, capturas, informes sin su OK. No usar `pkill -f <texto del propio comando>`.
- Ejecutar en primer plano: comandos cortos, en pasos separados.
- Norma de código: **ningún script > 450 líneas** (`herramientas/revisar_lineas.py`, `pruebas/comprobar_scripts.gd`). Código nuevo nace
  < 450. Partir con `herramientas/partir_gd.py` (capas por herencia; la última conserva ruta y class_name).
- Antes de SUBIR: `dinastia-godot/herramientas/banco.sh` debe terminar en «FIN. 0 fallos» (corre en paralelo; ~83 s). Mientras se trabaja:
  `mini_banco.sh <grupo>`. Lo que el banco no ve: `dinastia-godot/herramientas/especiales.sh [todo]`. Si el banco se cuelga: error de
  sintaxis; debe aparecer «===== FIN». Sección nueva = función en `pruebas/banco/<grupo>.gd` (o `varios`) + nombre en `SECCIONES` (y `GRUPOS`) de `pruebas/banco.gd`; si falta una, FALLO.
- Lo visual se revisa en Forward+ y con la CÁMARA REAL del partido (no solo de cerca): `herramientas/captura.sh`. Capturas en JPG.
  No quitar ni apagar nada sin decirlo.
- Contenedor nuevo: `git lfs pull --include="dinastia-godot/**"` ANTES de abrir Godot. Godot 4.7.2 se baja de GitHub releases.
  Clonar con `--single-branch --branch main` (las ramas viejas pesan). Tras clases nuevas: `godot --headless --import`.
- Datos de caras reales fuera de los builds públicos. Legal: la licencia libre cubre la foto, no el derecho de imagen.
  (30-10, opción B) TODOS los presets son públicos; lo real va en `caras_reales.pck` (`herramientas/empaquetar_caras.gd`),
  que `PaqueteReal` monta si está junto al ejecutable o en user://. El .pck NO se publica ni va al repo.
- `datos/idiomas_extra.json` (9 idiomas) round-trips con `json.dumps(ensure_ascii=False, indent=1)`; textos nuevos de UI con `Idiomas.t`.
- Diálogos de ciudad y narración se GENERAN (`herramientas/dialogos_ciudad.py`, `montar_narracion.py`): no editar a mano los resultados.
- En el motor del partido, no usar dicts de jugador como clave: usar `p["id"]`.
- Memoria del menú (3-11): el menú NO nombra clases de la ciudad, del estadio/partido 3D ni de las pantallas perezosas (Godot compila todo lo
  que se nombra). Ciudad: `CargaCiudad.de("Clase")`; resto: `load("res://…")` o `_pantalla_perezosa`; nada de `var _x := Clase.new(self)` en `Principal`.
  Pruebas: `mem_menu_estadio`, `prueba_menu_ciudad_pie`; medir con el `.pck` precompilado (`docs/04_auditorias/compilacion_menu_2026-11-03.md`).
- Extensión C++ (`nativo/src` → `bin_nativo/`, 30-10): cada función es copia exacta de su versión GDScript (que se queda como respaldo para Android/Web). Si se toca una de las dos, recompilar (`herramientas/compilar_nativo.sh`) y `pruebas/probar_nativo.tscn` debe dar «FIN. 0 fallos».
- SonarCloud (regla del dueño, 5-11; detalle y tabla de avisos en `docs/01_metodo/SONAR.md`): meta = puerta de calidad en verde en cada PR y 0 issues abiertos en `main`. Un aviso se VERIFICA y se arregla por causa, sin cambiar el comportamiento del juego a ciegas.
  Rutas por argumento: `herramientas/ruta_segura.py` (`open(ruta_segura(x))`); `NOSONAR(regla): motivo` solo donde la regla lo admite (no en seguridad ni flujo de datos). Los falsos positivos los acepta el dueño en la web de SonarCloud; las sesiones no escriben ahí. `terceros/` está excluido (`.sonarcloud.properties`).
  Informe: `SONAR_TOKEN=… python3 dinastia-godot/herramientas/sonar_informe.py` → `docs/04_auditorias/sonar_AAAA-MM-DD.{json,md}` (la sección «Gestión» a mano se conserva). El token NUNCA va al repo. Un CI rojo no se relanza hasta entender la causa.

## Órdenes vigentes del dueño (24-10)
1. Fases 0-6 del guion y decisiones validadas (punto 4 = separar `Principal` en clases + cifras fase 4): en `docs/PLAN_GENERAL.md` §2.
2. **Lunes (26-10)**: Foundry/Azure, red a Wikimedia, imagen Godot 4.7 para el CI, empezar la fase 0 real (`PLAN_GENERAL.md` §1-2).
   Hasta entonces: solo fallas, pendientes, mejoras y limpieza.
3. El dueño borra él las 8 ramas viejas (4 originales + 4 `borrar-*`) y la etiqueta `latest`.
4. Mega auditoría 3 hecha el 24-10 (`docs/04_auditorias/`); método Cascada + V en `docs/01_metodo/`. El 24-10 se borró lo viejo (planes, informes, capturas, vídeos, filas hechas) y el dueño pidió: ideas hechas se revisan «realmente bien», no solo «decentes»; lo no cerrado vive en el plan del lunes.
5. Idiomas: 9 y no sumar más. Las ~506 frases pendientes se tradujeron el 26-10 (sesión 1); lo nuevo, siempre con `sumar_traducciones.py`.
6. Pendientes de dueño: FPS en hardware real, builds, keystore, licencias, subir binarios a Drive (`herramientas/drive_subir.ps1`).
7. LFS (26-10): el dueño autorizó subir los sonidos de interfaz (CC0) y los PNG del logo. Desde este contenedor GitHub rechaza las subidas a LFS: archivos pequeños van fuera de LFS con una excepción en .gitattributes (ya hecha para audio/ui/*.ogg). Nada más sin preguntar.
8. Avisos (26-10): avisar al dueño con un evento de Google Calendar (recordatorio emergente a los 0 min, título «Dinastía: …») cuando haya una pregunta para él, se acaben las tareas, o la otra sesión pida algo o termine. La notificación push no le llega.
9. Sesiones (26-10): coordina y reparte la sesión «Sesiones abiertas» (session_01Vh9g2WJE8b9XRhTkoJQkJC). La sesión de trabajo principal (session_01MtJBCsXzXVcDXqPJ2uAkHW, rama ccr-76d707c5-dwse9h) evalúa, trabaja, une ramas y pregunta ante dudas; las dos se consultan como balanza. Nadie queda parado: al terminar, auditar o pulir del plan.
10. (26-10 noche) Calidad visual: ciudad por zonas (detalle, construcción, coherencia) y personajes (anatomía, movimiento natural,
    más animaciones, profundidad) por PASADAS con captura antes/después y veredicto del dueño; plan en `PLAN_GENERAL.md` §2.2e.
    La sesión líder (session_016d4XAEpSpuptrGg8J4Wene) manda y reparte; la ejecutora (session_01VUJiyfwiM2ZPT2H3gaDzqg) nunca queda parada.
11. (26-10 noche, decisiones del dueño) Fases 1-3 APROBADAS sin jugarlas aún, dejando constancia de que a futuro hay que pulirlas.
    Fusionar a `main` los PR #12 y #13: concedido («funciona»). Borrar capturas e informes viejos de `dinastia-godot/`: concedido
    (hecho: `pruebas/capturas` y `docs/informes_extraidos`); `marca/` se CONSERVA (tiene el logo para la animación de la intro).
    Red para Wikimedia/banderas: todavía no. El dueño está cerca de su tope de uso: trabajar en bloques pequeños, guardar y empujar a menudo.
12. (27-10) Veredicto del dueño sobre las pasadas visuales P1-P3: «MEJORAR». Regalos de Drive: licencia libre y gratuita confirmada
    por él. Órdenes nuevas: el MUSEO tiene que poder EXTENDERSE (por eso el ascensor) con una animación de expansión; la CIUDAD
    ENTERA más completa: muchas partes sin rellenar y RECURSOS SIN USAR (inventario en `docs/04_auditorias/recursos_sin_usar.md`).
    «Lo del museo y rellenar ciudad» va a la sesión ejecutora.
13. (27-10, decisiones del dueño) TÁCTICA: sí, pero en la pasada FINAL del motor, junto con lo visual, la IA de la CPU, el
    comportamiento, el físico, el pasto (regalo `grass.blend` en Drive, a evaluar), las físicas y más sonidos. VEHÍCULOS: suavizar y
    hacer más realistas autos, metro y bus, crear el tren y mejorar el teleférico. TIRO_PULIDO: ENCENDIDO, pero hay que pulirlo más.
    ESTADIOS: separar un poco a los aficionados en las butacas, subir la calidad de las butacas, mejorar los accesos y colorear las
    butacas por nivel según el color del club (y elegible en la personalización del menú inicial).
14. (27-10 tarde, decisiones del dueño) SÍ a clasificar las ~1.200 ideas (lanzamiento / después / descartar). `main` limpio y las
    ramas viejas: el dueño dice que ya lo hizo (verificar). PANTALLA DE ENTRADA nueva: APROBADA. «EL BLOQUEO» de modos: ACEPTADO
    (opción en Ajustes). Escenas de prueba sin mención: reutilizadas las 62 que pasan (bloque «reutilizadas» de `especiales.sh`, 2-11); capturas, diagnósticos y vídeos se quedan; no borrar nada sin decirlo. PEATONES: SÍ suben al
    bus y a los demás transportes. DIFICULTAD DE LA CPU en 8 categorías: Practicante, Cadete, DEBUTANTE (la normal), Semiprofesional,
    Profesional, Experto, Maestro, Ultimate; y además dificultades fuera del partido (eventos, probabilidades, retos, poca ayuda,
    asistentes deficientes, malos consejos y otras). POLICÍA Y BOMBEROS: sí. MUSEO: mejorarlo más y poder INTERACTUAR con los
    trofeos. PELO: usar los cortes y personajes del Drive. Pasadas visuales P1-P3: repetir «MEJORAR». PELUCHES: sí a las
    propuestas (monedas de 1 € del efectivo, una sala en el centro comercial, subir los 14 peluches reducidos fuera de LFS) y además
    COLECCIONABLES que den LOGROS. FPS en PC y móvil: cuando el dueño tenga el equipo listo. Pasto: traerlo del Drive.
15. (27-10 noche, decisiones del dueño) LICENCIAS: el dueño las tiene todas y no se usan fotos de personas en lo público
    (M-421/M-424 cerrados). Carpeta del Drive compartida como lector (pasto, trofeo base, pelo, personaje, foco, garra, silla, sala TV).
    BASE «FICTICIA» DE CLUBES: se queda como está y se COMPLETA: mismas estadísticas físicas y carrera de cada jugador, nombre un
    poco modificado pero reconocible; clubes igual; ESCUDOS que se parezcan más al real; uniformes base iguales; estadio con sus
    colores; los TROFEOS que tenga hoy cada club, modelados a partir del trofeo base del Drive (`gold+trophy.glb`) y modificados
    para parecerse; sus datos guardados en la historia del club. POSICIONES: se quedan en español en todos los idiomas.
    Política de privacidad: publicarla después. PARADEROS: que se parezcan a los de Chile (forma y carteles).
16. (27-10 noche) PELO y PERSONAJES del Drive: licencia confirmada por el dueño. PARADEROS «Red» (nombre basado en Red Movilidad, permitido):
    modelo real en las fotos del dueño (techo blanco con tirantes rojos, cabecera negra «Paradero de Red Movilidad | Parada N» con
    remates rojos y logo, panel publicitario Red, banca de láminas, papelero; POSTE con cartel NEGRO: iconos arriba, nombre de la
    parada, cuadrícula de recorridos en blanco, QR y franja roja abajo). El CÓDIGO del paradero sirve en una APP del móvil: qué micros
    pasan, en cuánto llegan y su patente. Recorridos: números por SECTOR (100: 122, 150, 190; 200: 203, 217, 278…), sufijo «c» =
    sentido contrario, «e» = alternativa (rara); hay también recorridos tipo «C02», «C09c».
17. (27-10 noche) RECORRIDOS SOBRE EL MAPA: los recorridos Red se crean a partir del mapa real de la ciudad (calles y líneas de
    `CiudadExpansion`, el mapa de transporte), y de ahí salen los paraderos (en las paradas de cada recorrido), su NOMBRE (la calle y
    la que cruza), su código PA####, los números de recorrido (por sector, con su «c») y las patentes de los buses.
18. (28-10) CIERRE hasta el lunes: tras la limpieza de código y lo pendiente de las sesiones, guardar todo y dejar registros
    al limpio. Registro: `docs/04_auditorias/CIERRE_2026-10-28.md`; estado para retomar arriba de `PLAN_GENERAL.md`.
    Correo de contacto del dueño (informe de fallos y privacidad): en `Registro.CONTACTO`.
19. (2-11) 120 FPS mínimo en equipos modestos (4 GB DDR3, Intel UHD/HD, Pentium): optimizar sin quitar nada sin decirlo y medir con `herramientas/hw_modesto.sh` (llvmpipe: comparar triángulos, llamadas, memoria; NUNCA el tiempo de fotograma `--headless`, tiene un suelo de 6,9 ms). El dueño ordenó (2-11) pasar todo a `main`. Estado y pendientes: `docs/04_auditorias/rendimiento_120fps.md` y arriba de `PLAN_GENERAL.md`.
19. (01-11) TERCEROS: «agarrar todo» de League-Soccer (Apache 2.0) y soccer5v5 (MIT) y quedarse siempre con lo MEJOR; lo que no
    se use queda de respaldo en `dinastia-godot/terceros/` (Godot no lo importa). Sus datos REALES (jugadores, escudos, uniformes,
    competiciones) NO se copian: solo su DIRECCIÓN en `terceros/league_soccer/DIRECCION_DATOS_REALES.md`, para recrearlos
    después de forma legal. Animaciones de League-Soccer: `herramientas/league_anim_a_res.gd` → `anims_league/league.res`.
20. (01-11) ORDEN DE TRABAJO del dueño: 1) FALLOS (los 8 que League-Soccer ya resolvió, `docs/04_auditorias/terceros_gestion_recursos_2026-11-01.md` U7),
    2) CLUBES (recrear de forma legal con `terceros/league_soccer/DIRECCION_DATOS_REALES.md`), 3) IA (R1-R3, U1-U8 de `terceros_ia_motor_2026-11-01.md`),
    4) jugabilidad, 5) optimización, 6) detectar fallos, 7) sonidos de sistema, 8) minijuegos, 9) entrenamiento.
21. (01-11 noche) Seguir las fases de la orden 20 SIN parar hasta terminarlas TODAS (3 IA: R2 y U8; 4-9) y avisar al dueño
    (Calendar) SOLO al final, con el resumen; no avisar fase por fase. Al final: dos VÍDEOS (un partido con la cámara real y un
    recorrido del juego entero: menú, ciudad, estadio, museo, gestión, partido, minijuego), grabados con `--write-movie` + xvfb +
    ffmpeg, fuera del repo (scratchpad → app y Drive). El dueño pone nota 1-100 con argumentos, que pasan a la lista de mejoras.
    (02-11) El dueño pidió SOLO el vídeo del partido (enviado: 2 partes comprimidas a 960x540, Lautaro 2-1 Marga Marga); su nota queda
    pendiente. Lo pidió más nítido: la regrabación en 1080p se cortó a medias (tarda ~7 h por software); queda el script
    `herramientas/grabar_partido_hd.sh` para hacerlo en un PC con GPU o rehacerlo aquí.
22. (3-11) PRUEBA DEL DUEÑO EN SU TELÉFONO: el plan del lunes queda en PAUSA salvo el código duplicado (M-391) y el
    rendimiento. Manda `docs/04_auditorias/PRUEBA_DUENO_MOVIL_2026-11-03.md` (5 FPS en MEDIA con la GPU al 100 % y la CPU al 0 %;
    objetivo 60 FPS; calidad por defecto la más baja; jugabilidad «muy mala»; ARENA DE PRUEBAS aislada para probar piezas sueltas).
23. (3-11) El DUEÑO se encarga de la JUGABILIDAD del partido y de los F1-F8 de la pasada final del motor (colocación sin balón,
    roles dinámicos, desmarques, marcaje, carreras al espacio, línea de tiro, portero, «imagen mental»): las sesiones no los tocan.
    Sin 4.ª sesión.
24. (3-11 noche) La sesión «PES 6» (session_015HWWmjio56aXxN6bLo3tob, rama ccr-454350d9-9chain, PR #128) lleva TODO el partido puro:
    IA de los 22 (F1-F8) y comportamiento físico, trabajando sin parar (medir, investigar, cambiar con bandera, volver a medir);
    bitácora en docs/04_auditorias/IA_PARTIDO_BITACORA.md. La líder la dirige y la empuja cada ~20 min. Su rama no se une sin OK del dueño.
25. (3-11 noche) REGLAS DEL DUEÑO: (a) «CONVERSACIÓN CASUAL»: con esa palabra clave empieza un modo en que SOLO se habla y se
    anota (nada de trabajo), y termina cuando el dueño vuelve a decir la misma palabra; las sesiones siguen con lo suyo y el
    líder solo revisa y les asigna. (b) Toda tarea o idea nueva del dueño se registra en `docs/PLAN_GENERAL.md` (el antiguo
    plan del lunes, renombrado) y se BORRA de ahí cuando está completa del todo. (c) Ante dudas o dificultades: buscar en
    internet y en las fuentes que existan del tema antes de decidir.
26. (3-11 noche) DECISIÓN DEL DUEÑO: seguimos siendo «4 juegos en 1», pero las IDEAS NUEVAS QUEDAN EN PAUSA: solo los puntos más
    débiles de la evaluación (rendimiento real, partido + modo jugar partido en MÓVIL, foco, ciudad/visual, calidad técnica) y
    pulir lo que existe. Bancos: más de 30 especializados + uno EXTRA de rendimiento. Detalle y orden en `PLAN_GENERAL.md`.
27. (4-11) El líder se activa SOLO cada 20 min (cadena send_later «Revisar las 3 sesiones» + respaldo horario fijo) para unir lo
    terminado y asignar tareas a TODAS las sesiones; y el líder TAMBIÉN trabaja (no solo ordena): bloque propio del plan.
28. (4-11, sesión «Búsqueda de fallos») Cada 20 min, antes de buscar, comprobar que `main` está actualizado (`git fetch origin main`), fusionarlo en la rama de trabajo y revalidar los fallos anotados; los que `main` ya resolvió se BORRAN del apartado «FALLOS DETECTADOS» de `docs/PLAN_GENERAL.md`. Esa sesión solo busca y registra; no corrige.
29. (4-11 madrugada) PAUSA ordenada por el dueño: todas las sesiones terminaron su bloque, se unió todo y se apagaron las revisiones
    automáticas (cadena de 20 min y respaldo horario). Para retomar: «ESTADO AL CIERRE DEL 4-11» arriba de `PLAN_GENERAL.md`.
30. (4-11) REGLA DEL DUEÑO: al dueño se le habla SOLO en español, siempre (todas las sesiones, también en avisos y resúmenes).
31. (4-11) MODO CAZA DE FALLOS (orden del dueño, hasta nueva orden): todo a `main`; MEGA AUDITORÍA 4 con 5 repasos (líder + todas las
    sesiones, `docs/04_auditorias/MEGA_AUDITORIA_4/`); después TODAS las sesiones solo detectan y ARREGLAN fallos (bugs, cuelgues, lo que
    no se repite igual, reglas del proyecto incumplidas), llevando el juego al límite, sin parar; el líder las controla cada 20 min.
    Los fallos se ARREGLAN SIN PREGUNTAR al dueño (también los que cambian cómo se juega: se anotan en el hallazgo). La auditoría
    empieza SOLO cuando todo esté en `main` (PR #166 de PES 6 y PR #165 del líder); hasta entonces se ayuda a llegar a eso.
32. (4-11 tarde) DECISIONES DEL DUEÑO: (1) los bonos del club del humano valen también cuando el mundo se simula sin gestionar (se queda como está); (2) más butacas visibles en la grada del estadio propio SOLO en calidad ALTA; (3) MSAA apagado en MÍNIMA (R01); (4) recalibrar remates y goleadas del partido simulado; (5) comercios abiertos de 8:00 a 20:00. Después: guardar todo, a `main` y CERRAR la jornada (revisiones automáticas apagadas). (4-11) Además: (6) en calidad MEDIA tampoco se dibuja la ciudad alrededor del estadio durante el partido (−33 % de dibujo en el contenedor, las tribunas la tapan): APROBADO y hecho; y (7) agregado «Partido ligero» en Ajustes, aparte de la calidad, apagado por defecto (sin ajuste de color, rótulos 3D ni focos). Jornada CERRADA el 4-11 tarde: estado arriba de `PLAN_GENERAL.md`.
33. (9-11) REESTRUCTURACIÓN «SOLO CLUB» (dueño): la ciudad 3D queda APAGADA (interruptor en código, fuera del juego instalado, sin borrar; puede volver); el juego base es el club, sus instalaciones y la casa (conducir/delito solo ahí); menú = «Diseño de la ciudad» (gestión 2D, con política) + «Entrar al estadio»; mando: Cuadrado borra, R2 confirma; sin vistas aéreas. Detalle y orden de 4 pasos (fallos del partido → club → medir → C++/motor) en `PLAN_GENERAL.md`; el trabajo real empieza el lunes 16-11. Cualquier sesión puede tomar los 4 fallos del partido.
34. (10-11) REGLA DEL DUEÑO: NUNCA usar un solo equipo en ejemplos, capturas, vídeos, pruebas ni demostraciones. Cada club tiene plantilla, escudo, liga, metas y formación distintos: variar el club (y el país) en cada ejemplo y revisar con varios. Prólogo: el animado del motor se ELIMINÓ; el nuevo será la idea del dueño y obliga antes a subir la calidad de las instalaciones del club y de los modelos 3D (realismo y animación).
35. (10-11 noche, el dueño se va a dormir) ÓRDENES: las ligas con sus CLUBES REALES y su CANTIDAD REAL (ENG 20, ESP 20, ITA 20, GER 18, FRA 18, ARG 30, BRA 20…; nombres ficticios en lo público, reales solo en el pack); formación y estilo reales por club (hecho); escudos, uniformes y caras más realistas; estadios con la herramienta mejorada; terminar TODO `docs/PLAN_GENERAL.md` y el informe; pasar a C++ lo que se pueda (con su gemelo GDScript, regla de la extensión); COMPARAR la calidad contra el PES 2020. Con dudas: anotar y seguir con lo siguiente. Se puede unir a `main`, cerrar sesiones y crear otras (nivel Sonnet). Aviso cada 10 min (cadena `send_later`). Clave de SonarCloud: guardada como secreto del entorno para sonarcloud.io (el script se corre con `SONAR_TOKEN=proxy-injected`).
36. (10-11 noche) RESPUESTAS DEL DUEÑO a las 21 preguntas (detalle en `PLAN_GENERAL.md`, «RESPUESTAS DEL DUEÑO A LAS 21 PREGUNTAS»): motor nuevo solo visual; jugadores con campos fijos SÍ; ramas viejas: PERMISO para borrar las que ya están enteras en `main`; los `.mp4` de `marca/` se quedan (son ejemplos); versión 0.9.2 y lista para exportar; biblioteca de caras pública SÍ; móvil por defecto: Modo rendimiento y Ahorro de menús ENCENDIDOS y tope de 90 FPS; ULTRA BAJA no se toca; web móvil con texturas comprimidas; vertical con diseño propio; iconos dibujados por defecto; museo: planta extra por títulos con mini evento.
37. (10-11 noche) CIERRE ordenado por el dueño: cada sesión terminó SOLO lo que tenía en marcha, todo se unió a `main`, se documentó y las sesiones se ARCHIVARON; revisiones automáticas apagadas. Para retomar: «ESTADO AL CIERRE DEL 10-11 NOCHE» arriba de `PLAN_GENERAL.md`.
38. (11-11) MOTOR DEL PARTIDO, YA (dueño): el motor de League-Soccer pasa a ser la prioridad; criterio = JUGABILIDAD Y DIVERSIÓN por encima de las cifras reales. Sesiones: 9 = fase 4 (locomoción por animaciones, rama `sesion9-motor-fase4`); 10 = animaciones GRATUITAS con licencia que permita usarlas y distribuirlas en un juego comercial (CC0/CC-BY/MIT/Apache; nada NC), con catálogo etiquetado (`sesion10-animaciones`); 11 = comparador de TRES motores (nuestro, League, combinado) con selector A/B/C a ciegas en Ajustes, voto de diversión y cifras de diversión (`sesion11-comparador`). El líder une a `main` y revisa cada 10 min.
39. (11-11) DECISIÓN DEL DUEÑO: el motor del partido es el **C4** (League + nuestra decisión con balón + nuestra colocación con caché + nuestra locomoción; el más barato y con regates y duelos) y se sigue MEJORANDO. Pasa a ser el de por defecto en el partido jugable; el de siempre queda de respaldo detrás de una bandera y el selector A/B/C sigue para probar. Sesión 11: C4 por defecto + mando táctil estilo FC Mobile; sesión 9: mejorar C4 (guía de animaciones en nuestra locomoción, acciones y celebraciones, cadenas de pases). Criterio: diversión y jugabilidad.
