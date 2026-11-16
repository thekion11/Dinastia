# Capítulo 3. Arquitectura de Dinastía: cifras medidas del código

Informe académico AAA de Dinastía · Medición y redacción: 16-11-2026, sobre el commit `3db6e8eb` de la rama de trabajo (con dos archivos modificados sin subir por otra sesión: `ui/componentes/menu_lateral.gd` y `visor/interior_oculto.gd`, que no cambian los recuentos en más de diez líneas).
Convenciones: [M] medido en este capítulo con el comando citado · [D] documento del proyecto · [E] estimación · [F n] y [R n] fuentes externas (capítulos 2 y 11). Este capítulo no modifica código.

---

## Resumen

Se mide la estructura del código de Dinastía con herramientas de sistema y con la herramienta de contenido del propio proyecto. El juego tiene **2.354 scripts propios de GDScript con 338.521 líneas físicas** (sin `addons/` ni `terceros/`), repartidos en `ui/` (88.412 líneas), `visor/` (77.585), `nucleo/` (57.001), `pruebas/` (112.101), `herramientas/` (1.925) y `minijuegos/` (1.497) [M]. A ello se suman 42 sombreadores (3.814 líneas), 1.101 escenas, 52 archivos de datos JSON (25 MB) y una extensión nativa de **16 archivos C++ con 3.052 líneas** que expone **39 métodos** y se distribuye compilada para cuatro sistemas [M]. El mundo generado tiene **135 países con liga, 147 ligas, 2.206 clubes, 55.150 jugadores y 135 selecciones** [M], cifras que corrigen las del resumen ejecutivo (1.069 clubes, 62 ligas).

La regla «ningún script de más de 450 líneas» ha moldeado la arquitectura: **265 scripts son capas por herencia** («`_p1`, `_p2`…») de **108 familias**, y la distribución de tamaños muestra un acantilado en el límite: 68 scripts tienen entre 445 y 450 líneas y 32 exactamente 450, mientras que la mediana es 86 [M]. Dos scripts superan el límite (486 y 454 líneas). El motor del partido ocupa unas 11.800 líneas en seis familias de archivos y admite seis variantes de motor, 55 banderas `C4_*` y 14 variables `LS_*` [M]. El código de pruebas equivale al 33 % de las líneas, una proporción alta para un proyecto de este tamaño.

Se identifican doce riesgos de deuda técnica; los más graves son el tamaño frente a la capacidad del equipo, la cohesión artificial que introducen las capas por tamaño, los invariantes implícitos que se rompen en fronteras poco ejercitadas (el reloj de la mitad, capítulo 6), el espacio combinatorio de motores y banderas sin pruebas cruzadas, y unas 25.000 líneas de la ciudad 3D apagada que siguen compilándose y manteniéndose.

---

## 3.1 Introducción

### 3.1.1 Problema

El resumen ejecutivo afirma que Dinastía tiene «2.410 scripts .gd, ~339.000 líneas» y que «es un tamaño de estudio mediano» [D: `INFORME_AAA_2026-11-16.md` §0]. Esas cifras son correctas como orden de magnitud, pero no dicen cómo se reparte el código, qué parte es juego y qué parte es prueba, cómo condiciona la regla de tamaño la estructura, ni dónde están los riesgos. Un plan hacia la versión 1.0 (capítulo 9) necesita saber qué se puede tocar con seguridad y qué no.

### 3.1.2 Preguntas

- A1. ¿Cuánto código hay y cómo se reparte por carpetas y tipos de artefacto?
- A2. ¿Qué efecto tiene la norma de 450 líneas en la estructura?
- A3. ¿Qué contenido genera el juego hoy?
- A4. ¿Cómo está organizado el motor del partido y cuántas configuraciones admite?
- A5. ¿Qué parte está en C++ y qué ha aportado?
- A6. ¿Qué infraestructura de pruebas y de calidad gráfica sostiene el desarrollo?
- A7. ¿Qué riesgos de deuda técnica se desprenden de lo anterior?

---

## 3.2 Método

Todas las cifras de este capítulo se obtuvieron el 16-11-2026 en la raíz `dinastia-godot/` con estos procedimientos:

- **Archivos y líneas por carpeta**: `find <carpeta> -name '*.gd' | wc -l` y `find <carpeta> -name '*.gd' -print0 | xargs -0 cat | wc -l`. Se cuentan **líneas físicas** (incluidas las de comentario y en blanco); no es una medida de líneas lógicas. Se excluye `.godot/` (caché del motor).
- **Distribución de tamaños**: `wc -l` por archivo sobre los scripts propios (sin `addons/` ni `terceros/`), ordenados; se calculan media, mediana, percentiles 90 y 99 y máximo.
- **Capas por herencia**: archivos cuyo nombre termina en `_p<n>.gd` o `_p<n>_p<m>.gd`; la familia es el nombre sin ese sufijo.
- **Clases con nombre**: archivos con una línea que empieza por `class_name`.
- **Extensión nativa**: `nativo/src/*.cpp` y `*.h`; métodos expuestos = nombres distintos en `D_METHOD("…")`.
- **Banderas del motor**: cadenas literales distintas `"C4_…"` en `visor/`, `nucleo/` y `ui/`, y nombres distintos `LS_…` en `visor/`.
- **Contenido**: `godot --headless --path . res://herramientas/medir_contenido.tscn -- --salida=<json>` (genera el mundo completo con semilla fija y lee sus tablas), ejecutado en el contenedor.

**Límites del método.** Las líneas físicas sobreestiman el código ejecutable en los archivos muy comentados (el proyecto comenta mucho, con fechas y órdenes del dueño). El filtro por nombre de la §3.10 para la ciudad 3D es heurístico. El clon es superficial, por lo que no se pueden medir tendencias históricas con `git log` (solo hay historia desde el 13-11 en esta copia).

---

## 3.3 Tamaño y reparto

### 3.3.1 GDScript por carpeta

| Carpeta | Scripts | Líneas | % de líneas propias | Capas `_pN` | Scripts de 445-450 líneas |
|---|---|---|---|---|---|
| `ui/` | 430 | 88.412 | 26,1 % | 89 | 20 |
| `visor/` | 406 | 77.585 | 22,9 % | 83 | 25 |
| `nucleo/` | 274 | 57.001 | 16,8 % | 61 | 13 |
| `pruebas/` | 1.179 | 112.101 | 33,1 % | 32 | 10 |
| `herramientas/` | 17 | 1.925 | 0,6 % | — | — |
| `minijuegos/` | 48 | 1.497 | 0,4 % | — | — |
| **Propios** | **2.354** | **338.521** | 100 % | 265 | 68 |
| `addons/` (terceros integrados) | 9 | 774 | — | — | — |
| `terceros/` (respaldo, no lo importa Godot) | 47 | 1.427 | — | — | — |
| **Total** | **2.410** | **340.722** | — | — | — |

[M] El total coincide con el del resumen ejecutivo (2.410 scripts) y con los 2.401 que revisa `revisar_lineas.py` en el capítulo 5 (la diferencia son los 9 de `addons/`).

Lectura: el código de juego propiamente dicho (`ui/`, `visor/`, `nucleo/`, `minijuegos/`) suma **224.495 líneas** [M]. La interfaz es la carpeta más grande, por encima del visor 3D y del núcleo de simulación. Es coherente con un juego de gestión con muchas pantallas, y también con la observación del dueño de que «las interfaces están muy llenas» (orden 51): hay mucho código de interfaz que mantener.

### 3.3.2 Distribución de tamaños

| Estadístico (scripts propios) | Valor [M] |
|---|---|
| Número | 2.354 |
| Media | 143,8 líneas |
| Mediana | 86 líneas |
| Percentil 90 | 403 líneas |
| Percentil 99 | 450 líneas |
| Máximo | 486 líneas (`visor/motor_jugable_p5.gd`) |
| Scripts > 400 líneas | 243 |
| Scripts de 445 a 450 líneas | 68 |
| Scripts de exactamente 450 líneas | 32 |
| Scripts > 450 líneas | 2 (`visor/motor_jugable_p5.gd` 486, `visor/calidad.gd` 454) |

La distribución es muy asimétrica: la mitad de los scripts tiene menos de 86 líneas, pero el 10 % más grande llega a 403 o más y el percentil 99 coincide exactamente con el límite de la norma. Que 32 scripts tengan **exactamente** 450 líneas no es un accidente estadístico: indica que, cuando un archivo crece, se le añade hasta el tope y solo entonces se parte. Es un patrón conocido de las métricas convertidas en objetivo: la regla se cumple, pero los archivos viven pegados al límite, de modo que cualquier cambio pequeño obliga a partir (los dos incumplimientos actuales nacieron así: `motor_jugable_p5.gd` pasó de 449 a 486 líneas con el paso a C++ del 15-11, capítulo 5, F-03).

### 3.3.3 Otros artefactos

| Artefacto | Cantidad [M] |
|---|---|
| Sombreadores `.gdshader` (sin `terceros/`) | 42 archivos, 3.814 líneas |
| Escenas `.tscn` (sin `terceros/`) | 1.101 (de ellas 1.088 en `pruebas/`) |
| Datos `datos/*.json` | 52 archivos, 25 MB |
| `assets/` | 387 MB |
| `audio/` | 20 MB |
| Python en el repositorio (sin `terceros/`) | 196 archivos, 27.304 líneas |
| Extensión C++ (`nativo/src`) | 16 `.cpp` + 1 `.h`, 3.052 líneas |
| Binarios nativos (`bin_nativo/`) | 8 (Linux x86_64, Windows x86_64, Android arm64 y Web wasm32; depuración y publicación) |
| Flujos de CI (`.github/workflows`) | 4 (`actualizar`, `compilar`, `especiales-todo`, `plataformas`) |
| Documentación (`docs/*.md`) | 114 archivos, 354.548 palabras |
| `docs/PLAN_GENERAL.md` | 2.856 líneas |
| `CLAUDE.md` | 162 líneas, 57 órdenes numeradas del dueño |

Dos cifras llaman la atención. La primera, que la documentación (354.548 palabras) equivale a varios libros: es un activo para retomar el trabajo, pero también un coste, porque el documento de planificación mezcla pendientes con «estados al cierre» históricos y ha dejado de ser un plan legible (el resumen ejecutivo lo señala en su §4, punto 6). La segunda, que el 99 % de las escenas son de prueba: la batería de pruebas se apoya en escenas propias, lo que la hace potente (prueba la escena real) y lenta (capítulo 5: las especiales tardan más de dos horas en un solo proceso sin GPU [E del cap. 5]).

---

## 3.4 La norma de 450 líneas y las capas por herencia

### 3.4.1 El mecanismo

La regla fija de `CLAUDE.md` prohíbe scripts de más de 450 líneas. Para partir un script se usa `herramientas/partir_gd.py`, que lo divide en **capas por herencia**: `x_p1.gd` contiene la primera parte, `x_p2.gd extends` la anterior, y así hasta la última, que conserva la ruta y el `class_name` originales [D: `CLAUDE.md`]. El resultado es una cadena lineal de clases en la que cada capa ve todo lo de las anteriores.

### 3.4.2 Extensión

| Medida | Valor [M] |
|---|---|
| Scripts que son capas `_pN` | 265 (11,3 % de los propios) |
| Familias con capas | 108 |
| Scripts con `class_name` | 909 (38,6 %) |

Familias más largas (número de capas sin contar el archivo final):

| Familia | Capas | Comentario |
|---|---|---|
| `ui/principal` | 16 | `Principal`, la raíz de la interfaz: 17 capas (capítulo 7, §7.3.4) |
| `pruebas/banco/varios` | 14 | grupo «varios» del banco |
| `visor/motor_jugable` | 13 | el motor del partido; 12 capas más la final (capítulo 6, §6.3.1) |
| `visor/stadium_builder` | 11 | constructor paramétrico de estadios |
| `visor/city_builder` | 11 | ciudad 3D (apagada) |
| `nucleo/mundo` | 11 | simulación del mundo |
| `visor/ciudad_expansion` | 8 | ciudad 3D (apagada) |
| `ui/componentes/interior_instalacion` | 7 | interiores del club |
| `nucleo/prensa` | 7 | prensa |

### 3.4.3 Evaluación

La norma tiene ventajas reales que el proceso ha aprovechado: archivos que caben en una pantalla de revisión, diferencias pequeñas en cada commit y avisos de análisis estático localizados. Pero la partición por tamaño **no es una partición por responsabilidad**. El capítulo 6 muestra la consecuencia en el motor: la capa 5 contiene «agarrón, movimiento de los 22, animación, fuera de juego, `_tomar` y gesto del golpeo», y la 6 «`_patear`, cabezazo, entrada, disputas, recepción, jugadas, mejor pase, `_pasar_a`» [D: cap. 6 §6.3.1]. Las funciones que comparten un supuesto (por ejemplo, la física del balón que predice el pase y la que lo mueve, M6-06) quedan en capas distintas y en archivos de otras familias, sin una interfaz que declare el supuesto.

Tres efectos de segundo orden:

1. **Acoplamiento total dentro de la cadena.** Una capa puede leer y escribir cualquier variable de las anteriores. El estado del motor (relojes, plazos, diccionarios de jugador) es, en la práctica, global para 13 archivos. El capítulo 6 encontró 31 claves de plazo distintas escritas desde varias capas con la misma convención implícita (§6.3.3).
2. **Orden de inicialización frágil.** Al partir un archivo, el orden de las funciones pasa a ser un orden de clases; mover una función de capa cambia qué ve y qué sobrescribe.
3. **Coste de compilación del menú.** La regla de memoria del menú (orden del 3-11) existe porque Godot compila todo lo que se nombra: cada `class_name` es una dependencia potencial. Con 909 clases con nombre, la disciplina de no nombrar clases de la ciudad o del partido desde el menú es necesaria y frágil a la vez [D: `CLAUDE.md`, «Memoria del menú»].

La alternativa que la literatura de ingeniería recomendaría —módulos con interfaz explícita en lugar de capas— no es un cambio que convenga hacer de golpe en un proyecto de 338.000 líneas. Lo que sí es razonable es aplicarla en los puntos donde ya ha causado fallos: la física del balón (que cada pieza intercambiable de C4 lleve su modelo, cap. 6 §6.7.3) y los relojes del motor (un reloj monótono para plazos, cap. 6 §6.7.1).

---

## 3.5 Subsistemas y contenido generado

### 3.5.1 Subsistemas

| Subsistema | Dónde | Qué contiene | Evidencia |
|---|---|---|---|
| Simulación del mundo | `nucleo/mundo*`, `liga`, `copa`, `partido*`, `finanzas`, `cantera`, `prensa*`… | Calendario, ligas, copas, continentales, partido simulado de la IA, economía, plantillas, cupos, cierre de temporada | cap. 7 §7.3 |
| Carrera de jugador (La Ruta) | `nucleo/carrera_*`, `ui/carrera/`, `visor/gala_*` | Progresión, habilidades, premios, rival, galas 3D | cap. 7 §7.3.1 |
| Guardado | `nucleo/partida*` | Instantánea JSON comprimida con huella | cap. 7 §7.3.3; cap. 5 §5.3.3 |
| Partido jugable | `visor/motor_*`, `league_*`, `mejoras_c4*`; integración en `ui/estadio*` y `ui/partido_jugable*` | Motores, IA, reglamento, cuerpos | cap. 6 |
| Estadio y club 3D | `visor/stadium_builder*`, `edificio_club*`, `interior_*`, hinchada | Estadios paramétricos, público, interiores | cap. 3 §3.5.2 |
| Interfaz | `ui/principal*` (17 capas), `ui/componentes/`, `ui/pantallas/` | Menú central, menús laterales, pantallas a pantalla completa, caché `MenuGuardado` | cap. 7 §7.3.4 |
| Calidad gráfica | `visor/calidad*`, `ModoRendimiento`, `RendimientoAdaptativo` | 7 niveles, modo rendimiento, «Partido ligero» | §3.9 |
| Ciudad 3D (apagada) | `visor/city_builder*`, `ciudad_expansion*`, `explorador_ciudad*`, tráfico | Ciudad, transporte, peatones | §3.10 |
| Extensión nativa | `nativo/src`, `bin_nativo/` | Funciones calientes con gemela GDScript | §3.7 |

### 3.5.2 Contenido generado (medido hoy)

`herramientas/medir_contenido.tscn` generó el mundo completo con semilla fija en el contenedor [M]:

| Magnitud | Valor [M] |
|---|---|
| Países con liga | 135 |
| Ligas | 147 (135 primeras divisiones y 12 segundas) |
| Clubes | 2.206 (1.958 en primera, 248 en segunda) |
| Jugadores en clubes | 55.150 (POR 6.618, DEF 17.648, MED 17.424, DEL 13.460) |
| Nacionalidades de jugadores | 150 |
| Media general (OVR) de los jugadores | 48,8 |
| Selecciones | 135 (UEFA 53, África 29, Asia 27, Concacaf 14, Conmebol 14, Oceanía 2) |
| Torneos continentales de clubes | 6; torneos FIFA de clubes: 2 |
| Países con fase final de liga (play-offs, grupos) | 15 |
| Caras en la biblioteca pública | 300; `caras_reales.pck` presente: no |
| Estadios: firmas visuales efectivas distintas | 2.203 de 2.206; núcleos arquitectónicos distintos: 783; repetidos dentro de una liga: 0 |
| Aforo medio / máximo | 16.415 / 95.000 |
| Escudos: firmas distintas | 2.069 |
| Uniformes con kit propio / firmas distintas | 2.166 / 1.045 |

**Discrepancia documentada.** El resumen ejecutivo y la comparativa del 10-11 hablan de «1.069 clubes, 62 ligas, 50 países, 26.725 jugadores, 69 selecciones» [D: `INFORME_AAA_2026-11-16.md` §2.9; `COMPARATIVA_PES2020.md` §0], y la auditoría de contenido del mismo día da en su cabecera 1.541 clubes, 98 ligas y 86 países [D: `AUDITORIA_CONTENIDO_2026-11-10.md` §1]. Al final de la comparativa ya figura la cifra posterior a la «tanda 5»: 135 países, 147 ligas, 2.208 clubes, 55.200 jugadores [D]. La medición de hoy (2.206 clubes, 55.150 jugadores) confirma este último orden de magnitud con una diferencia mínima. Las cifras de 1.069 clubes corresponden a un estado anterior del mundo y no deben seguir usándose.

**Lectura.** En cantidad, el mundo de Dinastía supera las cifras declaradas de FC 27 en clubes (más de 800 clubes y selecciones) y ligas (más de 35) [F 17]. La cantidad no es calidad: la media general bajó de 55,3 (10-11, mundo más pequeño [D: `AUDITORIA_CONTENIDO_2026-11-10.md`]) a 48,8 porque se añadieron muchas ligas pequeñas; solo una fracción de los jugadores tiene datos fijos (3.911 el 10-11 [D]); y la propia comparativa advierte que los datos de las ligas pequeñas «son en parte de memoria» [D: `COMPARATIVA_PES2020.md`, final]. El capítulo 8 trata esta diferencia entre amplitud y fidelidad.

---

## 3.6 El motor del partido

### 3.6.1 Variantes y piezas

`nucleo/motor_eleccion.gd` declara seis motores que sabe crear la fábrica (`siempre`, `league`, `combinado`, `combinado_c2`, `combinado_c3`, `combinado_c4`) y fija `POR_DEFECTO := "combinado_c4"` [M: líneas 16 y 113]. El combinado tiene cuatro piezas intercambiables cuyo valor de base vive en `datos/motor_c_piezas.json`: `decide_con_balon = siempre`, `coloca_sin_balon = league`, `fisica_balon = league`, `locomocion = league`; la variante C4 pone además `coloca_sin_balon` y `locomocion` en «siempre» [M: `datos/motor_c_piezas.json`; `visor/motor_combinado.gd:44`]. Es decir, C4 = League + nuestra decisión con balón + nuestra colocación + nuestra locomoción, con la física del balón suelto de League, como dice la orden 39.

### 3.6.2 Tamaño

| Familia | Archivos | Líneas [M] |
|---|---|---|
| `motor_jugable*` (motor «de siempre», 12 capas + final) | 14 | 5.147 |
| `league_*` (núcleo portado de League-Soccer) | 12 | 2.504 |
| Módulos `motor_*` (mente, presión, carreras, colocación, parada, ventaja…) | 29 | 1.884 |
| `mejoras_c4*` | 8 | 1.086 |
| `motor_league*` | 2 | 817 |
| `motor_combinado` | 1 | 337 |
| **Total** | **66** | **11.775** |

### 3.6.3 Configuraciones

| Elemento | Cantidad [M] |
|---|---|
| Motores seleccionables por la fábrica | 6 |
| Piezas intercambiables del combinado | 4 (2 valores cada una) |
| Banderas `C4_*` distintas en el código | 55 |
| Variables `LS_*` (League) distintas | 14 |

El espacio de configuraciones es, en teoría, del orden de miles de combinaciones. En la práctica se usan pocas: la tabla de banderas de las sesiones 13 y 15 lista 32 filas, de las que siete quedaron encendidas por defecto (`C4_PACIENCIA`, `C4_BANDA`, `C4_FALTA`, `C4_NO_DETRAS`, `C4_SEGUIR`, `C4_APOYO`, `C4_HUECO`), a las que se suman las tres que la sesión líder encendió el 11-11 (`C4_DESMARQUES`, `C4_SPRINTS`, `C4_LARGOS`) y una perilla con valor (`C4_DESVIO` = 0,2); el resto quedó apagado tras medirse [D: `MOTOR_LEAGUE_SOCCER_PLAN.md`, «Mejoras de C4» y «Estado de las banderas de C4»]. La disciplina de medir cada bandera con 12+12 partidos de clubes de tres países (orden 34) es metodológicamente sólida; el riesgo es que las banderas apagadas siguen siendo código vivo que nadie prueba en combinación con las encendidas (§3.10, riesgo 7).

### 3.6.4 Comportamiento comparado de los motores

La comparación de 11-11 (6 partidos completos por motor en piloto automático, 2 × 240 s de reloj del motor, clubes de Chile, España y Brasil) da una imagen clara de por qué se combinaron [D: `comparar_tres_motores_2026-11-11.md`]:

| Por partido | Motor «de siempre» | League tal cual |
|---|---|---|
| Tiros | ~49 | ~5 |
| Goles | ~6 | ~1 |
| Regates | 21 | 5 |
| Cadenas de 5+ pases | 0,5 | 1,7 |
| Tiempo en juego | — | 93 % |

El motor propio era de «ida y vuelta» (mucha acción, poca construcción) y League un partido «quieto» que encadenaba pases. C4 buscó lo mejor de ambos; con las banderas actuales, en 48 partidos de clubes de seis países, da unos 4,4 goles, 8,2 tiros dentro del área y 3,5 cadenas de 5+ pases por partido [D: `MOTOR_LEAGUE_SOCCER_PLAN.md`, sesión 15]. Esas cifras se obtienen con mitades de 240 s de reloj del motor, no de 45 minutos simulados, y en piloto automático: son comparables entre variantes, no con un partido real ni con lo que vive un jugador humano.

### 3.6.5 Dos integraciones distintas

El motor se integra de dos formas: `VistaEstadio` (modo entrenador y «Entrar al estadio») lo avanza desde `_process` con un acumulador de pasos fijos de 1/60 s y rehace el estadio en el descanso del DT; `PartidoJugable` (Carrera y La Ruta) usa `_physics_process` y el mismo motor en todo el partido [D: cap. 6 §6.3.8]. Esta duplicidad explica que varios fallos afecten a un modo y no al otro (M6-01 solo al estadio; M6-02/03/08 sobre todo a la Carrera; M6-05/11 solo al estadio del DT). Es una fuente estructural de defectos: cada frontera (descanso, prórroga, cambio de ritmo) se resuelve de forma distinta según la integración.

---

## 3.7 La extensión C++ y sus gemelas

### 3.7.1 Regla y estructura

La regla del proyecto es que cada función nativa sea una copia exacta de su versión GDScript, que se queda como respaldo para las plataformas sin extensión, y que `pruebas/probar_nativo.tscn` compare ambas byte a byte («FIN. 0 fallos») [D: `CLAUDE.md`]. Hoy la extensión tiene 16 archivos C++ y expone 39 métodos [M]. Los archivos más grandes son `partido_90.cpp` (383 líneas, los 90 minutos del partido simulado de la IA con un generador PCG32 que reproduce el del motor), `league_portador_nativo.cpp` (378, decisión con balón de League), `dinastia_nativo.cpp` (363), `estado_nativo.cpp` y `league_equipo_nativo.cpp` (319 cada uno) [M]. Hay siete scripts de prueba de igualdad (`probar_nativo.gd`, que agrupa, y seis especializados: balón, equipo, estado, League, portador y casos límite, este último con 3.136 comparaciones), más `nativo_partido.gd` para el partido simulado [M: `ls pruebas | grep nativo`; D: `PASO_CPP_PLAN.md` §2j].

### 3.7.2 Proporción

La extensión son 3.052 líneas frente a 224.495 de código de juego en GDScript: **un 1,4 %** [M]. Es una estrategia de «puntos calientes», no de reescritura, y es coherente con lo que el propio proyecto midió: cruzar de GDScript a C++ cuesta del orden de 1-2 µs por propiedad leída de un objeto, y las funciones que leen muchas propiedades ganan poco [D: `PASO_CPP_PLAN.md` §4].

### 3.7.3 Qué ha aportado (cifras del proyecto)

| Pieza | Antes → después | Fuente |
|---|---|---|
| Semana del mundo entero (521 clubes) | 792 → 395 ms (−50 %) | [D: `PASO_CPP_PLAN.md` §2c] |
| Partido simulado de la IA (2.094 cruces) | 1.834 → 956 µs por cruce | [D: §2c] |
| Choques de cuerpos (`cuerpos_motor`) | 199 → 40 µs por llamada | [D: §2, punto 3] |
| Movimiento de los 22 (`mover_jugadores_fisica`) | 238 → 96 µs por paso | [D: `PLAN_GENERAL.md`, «ESTADO AL 15-11»] |
| Decisión con balón de League (`league_decidir`) | 76 → 13 µs | [D: §2h] |
| Estado por paso de League | ~1.160 → ~960 µs por paso (±10-20 % de ruido) | [D: §2j] |
| Web (wasm32), partido simulado | 1.752 → 996 µs | [D: §2i, Web] |

La extensión ha dado su mayor beneficio en la **simulación del mundo** (la semana se redujo a la mitad), donde el trabajo es aritmético y masivo. En el **partido 3D** el beneficio es real pero pequeño respecto al fotograma: el paso del motor es aproximadamente un 9 % de un fotograma a 60 FPS, y el capítulo 4 muestra que el fotograma de la laptop no baja de unos 10 ms aunque el motor se apague [D: `INFORME_SESION_2026-11-15.md` §3; `PLAN_GENERAL.md`].

### 3.7.4 Riesgos propios de las gemelas

1. **Las gemelas reproducen los fallos.** La igualdad byte a byte garantiza que C++ y GDScript hacen lo mismo, no que hagan lo correcto: M6-03 estaba en `mover_nativo.cpp:119` exactamente igual que en `motor_jugable_p5.gd:186` [D: cap. 6 §6.7.5]. Cada arreglo en una función con gemela obliga a tocar dos lenguajes y recompilar ocho binarios.
2. **Plataformas sin verificar.** La DLL de Windows usa la biblioteca matemática de MinGW msvcrt, que puede diferir en un bit en `pow`, `sin` o `exp`; la de Android arm64 se compiló con `-ffp-contract=off` pero no se ha probado en un teléfono [D: `PASO_CPP_PLAN.md` §2j, riesgos]. Si un bit difiere, las huellas de simulación dejan de coincidir entre plataformas.
3. **Robustez divergente deliberada.** Con entradas inválidas, el C++ salta nodos liberados donde el GDScript aborta [D: §2j]: el comportamiento ante datos corruptos ya no es idéntico.

---

## 3.8 Infraestructura de pruebas

| Elemento | Cifra | Fuente |
|---|---|---|
| Código de pruebas | 1.179 scripts, 112.101 líneas (33,1 % del código propio) | [M] |
| Banco (`banco.sh`) | 52 scripts de grupo (18.469 líneas); 5.457 comprobaciones en ~367 secciones; 176 s en 4 partes paralelas en el contenedor | [M]; [D: cap. 5 §5.2.2] |
| Especiales (`especiales.sh`) | 397 pruebas; ≈82 min en tres procesos sin GPU | [D: cap. 5 §5.3.1] |
| Igualdad nativa | 7 scripts `probar_nativo*` + `nativo_partido.gd` | [M] |
| Herramientas de medida `zz_*` | 63 escenas | [M] |
| Huellas de simulación | p. ej. 2244399493 / 3725505167 (motor y mundo) | [D: `PLAN_GENERAL.md`] |
| Análisis estático | SonarCloud, 0 avisos abiertos tras el 12-11 | [D: `CLAUDE.md`, orden 43] |
| Cobertura | de funciones 83 %; sin cobertura de líneas de GDScript | [D: `PLAN_GENERAL.md`, «FALLOS DETECTADOS»] |

Un tercio de las líneas dedicadas a pruebas es una proporción alta para un proyecto pequeño. El capítulo 5 matiza su eficacia: el banco terminó en verde, pero las especiales tenían 8 fallos reproducibles del proyecto; el banco no convierte en fallo los `ERROR:` del motor que no son `SCRIPT ERROR`; y la norma de líneas no forma parte del criterio de subida [D: cap. 5 §5.7]. El capítulo 7 añade que las pruebas de La Ruta usan diccionarios en memoria y no una ida y vuelta real por JSON, y llaman a las funciones en un orden distinto del de la interfaz [D: cap. 7 §7.7]. La cantidad de pruebas es alta; su capacidad de encontrar fallos en las **fronteras** (descanso, carga desde disco, frecuencias de fotograma reales) es baja.

Una observación adicional: `CLAUDE.md` cifra el banco en unos 83 s, pero en el contenedor de cuatro núcleos tardó 176 s [M del cap. 5]. La diferencia probablemente se debe al hardware; conviene no usar la cifra de 83 s como límite de tiempo en el CI sin medirla allí.

---

## 3.9 Calidad gráfica en siete niveles

`visor/calidad.gd` define `enum { ULTRA_BAJA = -3, BAJA = -2, MEDIA_BAJA = -1, MEDIA = 0, MEDIA_ALTA = 1, ALTA = 2, ULTRA_ALTA = 3 }` con alias para el esquema antiguo (`MINIMO = ULTRA_BAJA`, `MEDIO = MEDIA`, `ALTO = ALTA`, `ULTRA = ULTRA_ALTA`) y `NIVEL_DEFECTO := ULTRA_BAJA` en todos los sistemas [M: líneas 27-32]. El propio archivo reconoce que **MEDIA ALTA «se comporta como MEDIA hasta que se refine»** y que BAJA y MEDIA BAJA «caen del lado ligero de MEDIA» [M: comentario de la línea 26]. Por tanto, de los siete niveles nominales, al menos uno no tiene comportamiento propio, y los niveles intermedios se distinguen sobre todo por la escala del 3D y por funciones con nombre añadidas después.

Parámetros medidos o declarados en el código:

| Parámetro | Valor | Fuente |
|---|---|---|
| Escala 3D en ULTRA BAJA | 40 % por defecto (35-100 % en Ajustes) | [M: `ESCALA_MINIMO := 0.4`] |
| Escala 3D en ULTRA ALTA (Forward+) | 60 % con TAA | [M: `escala_ultra`; D: `PLAN_GENERAL.md`] |
| Sombra del sol | no en ULTRA BAJA y BAJA; con «Modo rendimiento», tampoco hasta MEDIA | [M; D: cap. 5 F-05] |
| «Modo rendimiento» | encendido por defecto en todas las plataformas desde el 15-11 | [D: cap. 5 F-05] |
| «Partido ligero» | aparte de la calidad, apagado por defecto | [D: `CLAUDE.md`, orden 32] |
| Llamadas de dibujo del partido (cámara de TV, contenedor) | MÍNIMO 338, MEDIO 709, ALTO 925 | [D: `calidad_7_niveles_2026-11-06.md` §0] |

La infraestructura es sofisticada (migración del número guardado, calidad adaptativa, prueba integrada de rendimiento), pero la interacción de tres ejes independientes —nivel, modo rendimiento, partido ligero— multiplica los estados posibles. El capítulo 5 mostró que dos decisiones legítimas del 15-11 (ULTRA al 60 % y modo rendimiento por defecto) dejaron cuatro pruebas desfasadas en rojo (F-05) y que la gala 3D fuerza su propia calidad al margen del nivel (F-04). El riesgo no es la cantidad de niveles sino la falta de una tabla única nivel × parámetro que las pruebas lean como oráculo, que el propio documento de diseño de los siete niveles dejó con celdas «por medir» [D: `calidad_7_niveles_2026-11-06.md` §3].

---

## 3.10 Riesgos de deuda técnica

| # | Riesgo | Evidencia | Impacto | Mitigación propuesta |
|---|---|---|---|---|
| 1 | **Tamaño frente a capacidad** | 224.495 líneas de juego, 112.101 de pruebas, 354.548 palabras de documentación [M]; un dueño y sesiones asistidas | Todo cambio transversal toca muchos archivos; el pulido se dispersa | Recorte de alcance a 1.0 (cap. 9, decisión del dueño); congelar lo que no entra |
| 2 | **Cohesión artificial por tamaño** | 265 capas, 108 familias; capas que mezclan responsabilidades [M; cap. 6 §6.3.1] | Supuestos compartidos sin interfaz (M6-06); estado global en cadenas de 13 archivos | Extraer módulos con interfaz donde ya hubo fallos: modelo físico del balón, relojes |
| 3 | **Acantilado en 450 líneas** | 68 scripts de 445-450, 32 de exactamente 450, 2 por encima [M] | Cada cambio pequeño obliga a partir; los incumplimientos entran con el banco en verde | Meter la cuenta de líneas en el criterio de subida (cap. 5 F-03); margen de seguridad (p. ej. 420) para código nuevo |
| 4 | **Invariantes implícitos** | Reloj `t` que vuelve a cero frente a 31 plazos absolutos (cap. 6 §6.3.3); tipos de JSON (G-01) | Fallos en fronteras poco ejercitadas: descanso, carga | Reloj monótono para plazos; ida y vuelta JSON en todas las pruebas de guardado |
| 5 | **Estado global temporal** | `MotorCombinado` vacía `equipos` y apaga una bandera estática durante llamadas (M6-24) | Oyentes que ven piezas falsas; frágil ante hilos | Pasar la elección por parámetro |
| 6 | **Doble mantenimiento de gemelas** | 39 métodos nativos, 8 binarios, 4 sistemas [M]; los fallos se reproducen en ambos lenguajes | Cada arreglo en una función caliente cuesta el doble; riesgo de libm distinta | Mantener la estrategia de puntos calientes; probar `probar_nativo` en Windows y Android reales |
| 7 | **Espacio combinatorio del motor** | 6 motores, 4 piezas, 55 banderas `C4_*`, 14 `LS_*` [M] | Combinaciones no probadas; código apagado que se degrada | Congelar C4 (decisión del dueño); retirar banderas descartadas tras un periodo; prueba de humo de las combinaciones del selector A/B/C |
| 8 | **Ciudad 3D apagada pero viva** | 107 scripts y ~25.094 líneas con nombres de ciudad, tráfico, transporte o explorador [M, filtro heurístico por nombre]; 2 fallos de ciudad sin arreglar por estar apagada [D: `PLAN_GENERAL.md`, «FALLOS DETECTADOS»] | Compila, se mantiene y ocupa pruebas sin aportar al juego 1.0 | Excluirla de los builds 1.0 y de las especiales rápidas; mantenerla en una rama o carpeta fuera del proyecto importado |
| 9 | **Jugadores como diccionarios** | El motor maneja jugadores como `Dictionary` con decenas de claves; comparaciones `p == q` por contenido; coste de cruce a C++ por propiedad [D: cap. 6 §6.6; `PASO_CPP_PLAN.md` §4] | Coste de CPU; errores de clave silenciosos; portar a C++ deja de compensar | Para 1.0, no tocar; a largo plazo, estructuras tipadas o arrays planos en lo caliente |
| 10 | **Oráculos de prueba desfasados** | 4 especiales en rojo tras decisiones intencionadas (F-05); banco que no ve `ERROR:` (cap. 5) | Rojo permanente que oculta regresiones nuevas | Tabla de calidad única como oráculo; fallo ante `ERROR:` con lista blanca |
| 11 | **Documentación acumulada** | `PLAN_GENERAL.md` 2.856 líneas con estados históricos; cifras de contenido contradictorias entre documentos (§3.5.2) | Sesiones que trabajan con cifras viejas | Separar histórico y pendientes; una sola fuente de cifras generada por herramienta |
| 12 | **Herramientas dependientes del entorno** | `revisar_lineas.py --nuevos` falla en clones superficiales; sin Forward+ ni Vulkan en el contenedor [D: cap. 5 E-04; `PLAN_GENERAL.md`, «FALLOS DETECTADOS», nº 6] | Comprobaciones que no se pueden ejecutar donde trabajan las sesiones | Caer a `--todos` sin base común; validar lo visual en la laptop |

### 3.10.1 Priorización

Los riesgos 3, 4 y 10 son baratos de mitigar y ya han producido fallos documentados: deben entrar en el saneamiento previo a cualquier pulido (capítulo 9, hito H0). Los riesgos 1, 7 y 8 dependen de una decisión de producto (alcance de 1.0 y congelación del motor) que corresponde al dueño. Los riesgos 2, 5, 6 y 9 son estructurales y conviene atacarlos solo donde un fallo concreto lo justifique, para no abrir una reescritura en mitad del pulido.

---

## 3.11 Conclusiones

1. **Dinastía es un proyecto grande para su equipo**: 338.521 líneas de GDScript propio, de las que 224.495 son juego y 112.101 pruebas, más 3.052 de C++ [M]. La interfaz es la carpeta más grande (88.412 líneas).
2. **La norma de 450 líneas se cumple casi siempre, pero ha creado un acantilado**: 32 scripts tienen exactamente 450 líneas y 68 están a cinco o menos del límite [M]. Las 265 capas por herencia parten por tamaño, no por responsabilidad, y concentran estado compartido sin interfaz, que es el terreno de los fallos de frontera del capítulo 6.
3. **El mundo generado es mucho mayor de lo que dicen los documentos anteriores**: 2.206 clubes, 147 ligas, 135 países, 55.150 jugadores y 135 selecciones [M]. La amplitud supera a la declarada por FC 27 [F 17]; la fidelidad no.
4. **El motor del partido ocupa unas 11.800 líneas y admite un espacio de configuraciones muy amplio** (6 motores, 55 banderas `C4_*`) [M], de las que se usan unas pocas. Hay dos integraciones con fronteras distintas, que explican la distribución de los fallos por modo.
5. **La extensión C++ es pequeña (1,4 % del código de juego) y eficaz donde el trabajo es aritmético** (semana del mundo −50 %) [M][D]; en el partido 3D su efecto sobre el fotograma es marginal (capítulo 4).
6. **La infraestructura de pruebas es abundante pero ciega en las fronteras**; la de calidad gráfica es sofisticada pero carece de un oráculo único.
7. Se identifican doce riesgos de deuda técnica; los tres más baratos de mitigar (acantilado de líneas, invariantes implícitos, oráculos desfasados) deben resolverse antes de pulir.
