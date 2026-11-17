# Capítulo 7. Fallos de gestión, La Ruta y menús: auditoría estática de corrección

Informe académico AAA de Dinastía · Redacción: 16-11-2026 · Código auditado: rama de trabajo a la altura del commit `b2f4f80d` (16-11-2026).
Convenciones del informe (ver `00_INDICE.md`): [M] medido · [D] documento del proyecto · [E] estimación. Cada hallazgo lleva archivo:línea, escenario reproducible, arreglo propuesto y veredicto (CONFIRMADO / PLAUSIBLE). Este capítulo **no corrige código**.

---

## Resumen

Este capítulo audita la corrección (no el estilo) de tres zonas del juego que viven fuera del partido: (a) «La Ruta», el modo jugador reescrito el 13-11-2026 (`nucleo/carrera_*.gd`, `ui/carrera/`, `visor/gala_*.gd`); (b) la gestión del club y el mundo simulado (finanzas, mercado, plantel y cupo, cierre de temporada, copas y guardado/carga); y (c) los menús principales (`Principal` en 17 capas, `MenusLaterales`, `MenuGuardado`). El método combina lectura dirigida del código, trazado de llamadores para cada sospecha y, donde la duda dependía del motor, una reproducción mínima con Godot 4.7.2 en modo sin pantalla.

Se registran **25 hallazgos**: 2 críticos, 5 altos, 7 medios y 11 bajos; 20 CONFIRMADOS y 5 PLAUSIBLES. Los dos críticos afectan a La Ruta y tienen la misma forma: un estado que el jugador cree seguro se pierde sin aviso. El primero es que el mundo simulado puede **retirar o dejar libre al futbolista del jugador** en el cierre de temporada (retiro a los 35-38 años, o contrato vencido sin renovar), y como `CarreraJugador.jugador()` solo busca en las plantillas de los clubes, la pantalla de La Ruta cae a la de «crear jugador» y el guardado automático sobrescribe la partida en ese estado. El segundo es que **cada carga de una carrera desde disco pone a cero los números de la temporada** (partidos, titularidades, goles y asistencias): Godot 4.7 devuelve todos los números del JSON como flotantes y la validación de tipos de `_stats_ok` los rechaza por no ser enteros; se reprodujo con el código copiado tal cual [M].

Los altos describen reglas del juego que el código anuncia y no cumple: los **retos del partido** se evalúan contra los retos de la semana *siguiente* (el mundo avanza antes de anotar el partido); los **premios que comparan notas** («Jugador del año del club», «Mejor jugador de la liga», «Mejor portero», «Mejor del mundo», MVP de copa y continental) nunca comparan con nadie porque exigen 10 o 20 notas a un historial que el núcleo recorta a 8; las **asistencias** no se acreditan a nadie en el partido simulado y no se reinician por temporada; los **torneos continentales desaparecen al cargar** una partida de La Ruta; y en La Ruta **el resto del mundo no entrena** semana a semana, porque esa fase está atada a que exista «tu club».

La discusión de diseño concluye que la estructura de progresión de La Ruta (experiencia en curva lineal creciente, siete capítulos, tres monedas de mejora, rival y premios) es coherente y potencialmente muy divertida, pero que hoy su economía de puntos tiene tres agujeros medibles en el propio código (el coste de una habilidad depende de cuántas sub-habilidades tiene su zona, el portero sube seis veces más barato y «pulir» con un punto de talento rinde hasta 38 veces más que la habilidad a nivel alto) y que varios de sus premios son automáticos por los fallos anteriores. Casi todos los fallos graves comparten una causa: las pruebas del banco trabajan con diccionarios en memoria y llaman a las funciones del núcleo en un orden distinto del de la interfaz, de modo que pasan en verde lo que en una partida real falla.

---

## 7.1 Introducción

### 7.1.1 Problema

Los capítulos 4 a 6 se ocupan del partido, que es donde el informe interno del 16-11 sitúa la mayor brecha frente a PES 2020 [D: `INFORME_AAA_2026-11-16.md`]. Pero un juego de fútbol de nivel AAA no se sostiene solo con el partido: la Liga Master de PES 2020 y el modo carrera de la serie FC se juegan durante decenas de horas, y su credibilidad depende de que el mundo alrededor sea coherente temporada tras temporada. En Dinastía esa capa es enorme (el núcleo tiene más de 300 scripts y `Principal` está repartido en 17 capas por la norma de las 450 líneas) y ha cambiado mucho en la última semana: La Ruta se escribió entre el 13 y el 14-11, la reestructuración «solo club» del 9-11 apagó la ciudad, y el 10-11 se añadió el cierre completo de torneos. Es la combinación clásica en la que aparecen fallos de integración: piezas correctas por separado que, juntas, rompen un invariante.

### 7.1.2 Objetivos

1. Encontrar fallos **reales** de corrección en La Ruta, la gestión y los menús: pérdida o corrupción de datos al guardar o cargar, migraciones, signos y unidades económicas, plantillas fuera de cupo, fechas que se desfasan, premios mal asignados (empates, divisiones por cero, umbrales imposibles), señales conectadas dos veces, nodos sin liberar, textos sin traducir e incumplimientos de las reglas fijas de `CLAUDE.md`.
2. Verificar cada sospecha leyendo el código alrededor **y sus llamadores**, y dejarla como CONFIRMADA (el camino de ejecución está demostrado o reproducido) o PLAUSIBLE (el defecto está en el código pero su efecto depende de condiciones que no se pudieron fijar estáticamente).
3. Valorar el diseño de la progresión de La Ruta con las cifras del propio código: ¿es coherente?, ¿es divertida?, ¿qué se rompe al jugarla muchas temporadas?

### 7.1.3 Alcance y exclusiones

Quedan fuera el motor del partido (capítulo 6), el rendimiento medido (capítulo 4) y la jugabilidad del partido, que según la orden 23 lleva el dueño. Tampoco se evalúan las decisiones de diseño ya aprobadas por el dueño (por ejemplo, que los bonos del club humano valgan con el mundo simulado, orden 32.1) salvo cuando el código no hace lo que la decisión dice. No se ha jugado ninguna partida completa: todas las afirmaciones sobre efectos en juego son deducciones del código, salvo las marcadas [M].

---

## 7.2 Método

### 7.2.1 Unidad de análisis y recorrido

La unidad de análisis es el **invariante**: una propiedad que el código promete (en un comentario, en el texto que ve el jugador o en una prueba) y que debería mantenerse entre llamadas. Ejemplos: «los retos que ves antes del partido son los que se juzgan con ese partido»; «cargar y seguir da lo mismo que no haber salido» (comentario del 4-11 en `carrera_jugador.gd:412`); «el premio *Mejor jugador de la liga* es para la mejor nota media de toda la liga» (`carrera_premios.gd:22`).

El recorrido siguió el flujo de una semana de La Ruta, que es el camino más largo y más nuevo:

1. Interfaz: `ui/carrera_jugador_ui_p1.gd` (`_cerrar_semana`, `_jugar_partido`, `_jugar_momentos`, `_ir_al_banco`, `_nueva_temporada`) y `ui/carrera_jugador_ui.gd` (`_pintar_semana`).
2. Núcleo de la carrera: `CarreraJugador` (dos capas), `CarreraRuta`, `CarreraPremios`, `CarreraHabilidad`, `CarreraTalentos`, `CarreraLogros`, `CarreraMisiones`, `CarreraEventosRuta`, `CarreraVida`, `CarreraEstilo`, `CarreraPatrocinio`, `CarreraDuelo`, `CarreraCopa`, `CarreraMomentos`, `CarreraComienzo`.
3. El mundo que la rodea: `Mundo.avanzar_semana` (`mundo_p5*.gd`), `Mundo.nueva_temporada` (`mundo_p7_p1.gd`), `_vence_contrato` (`mundo_p6.gd`, `mundo_p7.gd`), `PartidoDespedida.se_retira`, `Partido._cerrar_notas_gd`, `Jugador.anotar_nota`.
4. Persistencia: `Partida` (`partida.gd`, `partida_p1.gd`), `PartidaArchivo` y `CarreraJugador.a_dic/desde_dic`.
5. Gestión del club: `Finanzas`, `Cesiones`, `Federacion` (cupo de plantel y multas), `LeyesPais`, `Copa`, `CierreTorneos`, `PremioMensual`.
6. Menús: `Principal` (búsqueda de conexiones de señales en `ui/principal/*.gd`), `MenusLaterales`, `MenuGuardado`, y la regla de memoria del menú (que el menú no nombre clases de la ciudad, del estadio 3D ni de las pantallas perezosas).
7. Galas 3D: `visor/gala_premio3d.gd`, `gala_guiones.gd`, `ui/carrera/ruta_gala.gd`, contrastadas con `visor/calidad.gd`.

Para cada sospecha se buscaron sus llamadores con búsqueda de texto en todo `nucleo/`, `ui/` y `visor/`, y se comprobó si alguna otra pieza compensaba el defecto (por ejemplo, una conversión de tipos previa o un candado contra la doble conexión).

### 7.2.2 Verificación dinámica mínima

Dos dudas dependían del comportamiento del motor y se resolvieron ejecutando Godot 4.7.2 sin pantalla con guiones aislados en el directorio temporal de la sesión (fuera del repositorio):

- **Tipo de los números al leer JSON.** `JSON.parse('{"pj": 3, "x": 2.5}')` devuelve `typeof(pj) == 3` (TYPE_FLOAT), no 2 (TYPE_INT) [M].
- **Validación de `stats_temp` al cargar.** Se copiaron literalmente `_tipo` y `_stats_ok` de `carrera_jugador.gd:378-389` a un guion independiente, se serializó `{"pj": 12, "titular": 10, "goles": 7, "asist": 3, "notas": [7.0, 6.5]}` con la misma llamada que usa `Partida.guardar` (`JSON.stringify(datos, "", false, true)`) y se volvió a leer: el resultado fue `{"pj": 0, "titular": 0, "goles": 0, "asist": 0, "notas": [7.0, 6.5]}` [M].

Se intentó además ejecutar el núcleo real con `--path dinastia-godot --script`, pero el arranque del proyecto no terminó en varios minutos mientras otra sesión corría el banco completo en la misma máquina; se abandonó esa vía y no se usa ningún resultado de ella. El banco del proyecto (`banco.sh`) no se ejecutó en este capítulo: su estado lo trata el capítulo 5.

### 7.2.3 Criterios de gravedad

| Gravedad | Criterio |
|---|---|
| Crítica | Pierde o corrompe la partida o la carrera del jugador, o la deja en un estado del que la interfaz no sabe salir, en un escenario corriente. |
| Alta | Una regla del juego anunciada al jugador es falsa o el estado del mundo queda incoherente de forma visible, en un escenario corriente, sin perder la partida. |
| Media | Desequilibrio o dato incorrecto en escenarios frecuentes pero acotados, o una regresión de rendimiento en la calidad que el dueño prioriza (móvil, equipos modestos). |
| Baja | Cosmético, poco frecuente, de efecto pequeño, o incumplimiento de una regla interna sin efecto en juego. |

### 7.2.4 Veredictos

- **CONFIRMADO**: el camino de ejecución que produce el defecto está trazado de principio a fin en el código (con su llamador real) o se reprodujo [M].
- **PLAUSIBLE**: el defecto está en el código, pero que se manifieste depende de datos del mundo (ligas activas, plantillas, sorteos) o de detalles que no se pudieron fijar sin jugar.

### 7.2.5 Limitaciones

La auditoría es estática y de una sola persona; hay zonas (la economía de la IA, el mercado entre clubes de la IA, los 62 archivos de `ui/principal/`) que se muestrearon y no se recorrieron enteras. Las cifras de progresión de §7.6 son **estimaciones del código** [E], no mediciones de partidas: el proyecto tiene una sonda específica (`pruebas/_sonda/sonda_ruta.tscn`, orden 53) que debe usarse para confirmarlas tras los arreglos.

---

## 7.3 Arquitectura de lo auditado

### 7.3.1 La Ruta

La Ruta no es un modo con mundo propio: es una **capa sobre un `Mundo` normal** en el que `mi_club_id` está vacío y `carrera_jugador` apunta a un `CarreraJugador`. El futbolista del jugador es un `Jugador` más de una plantilla; el comentario de cabecera lo dice explícitamente: «la liga, el mercado y las lesiones lo tratan igual que a los demás» (`carrera_jugador_p1.gd:5-7`). Esa decisión es elegante (no duplica la simulación) y es también el origen de los dos hallazgos críticos: lo que el mundo hace con *cualquier* jugador también se lo hace al tuyo.

Todo el estado nuevo de La Ruta vive en un único diccionario, `CarreraJugador.ruta`, que se guarda con la partida y que `CarreraRuta.asegurar()` completa con sus claves por omisión (`carrera_ruta.gd:80-92`). Sobre él trabajan once clases estáticas, cada una con su parcela:

| Clase | Responsabilidad | Estado en `ruta` |
|---|---|---|
| `CarreraRuta` | experiencia, nivel, capítulos, retos semanales, racha, rival y duelo, «la grada» | `xp`, `nivel`, `puntos`, `racha`, `retos`, `rival`, `grada`, `ultimo`, `fama_ref`… |
| `CarreraHabilidad` | puntos de habilidad (6 por nivel), sub-habilidades por zona, cambio de puesto | `hab`, `hab_nivel`, `detalle`, `pulidos` |
| `CarreraTalentos` | puntos de talento: 9 talentos en 3 ramas, o «pulir» +2 | `talentos`, `puntos`, `pulidos` |
| `CarreraPremios` | cierre de temporada: 15 premios individuales y los trofeos del club, brazalete | `premios`, `temporada` |
| `CarreraLogros` | 18 logros propios con experiencia | `logros`, `cuenta`, `logros_nuevos` |
| `CarreraMisiones` | 3 misiones por capítulo, punto de talento al cumplirlas | `misiones_hechas` |
| `CarreraEventosRuta` | 14 eventos con decisión y cadenas por «marcas» | `marcas` |
| `CarreraVida` | ahorro del sueldo y 7 compras permanentes | `ahorros`, `vida` |
| `CarreraEstilo` | estilo de juego, curva de crecimiento, forma de −3 a +3 | `estilo`, `curva`, `techo` |
| `CarreraPatrocinio` | contrato de botas en tres niveles | `patro` |
| `CarreraDuelo` | corte de mitad de temporada del duelo con el rival | (marcas `corte`, `remontada`) |

La interfaz (`ui/carrera/`, 18 scripts) no guarda estado de juego: pinta a partir del núcleo y llama a `CarreraJugadorUI`, que es quien mueve la semana.

### 7.3.2 El orden de una semana de La Ruta

Este orden es el que importa para varios hallazgos, así que se reproduce tal como está en `_cerrar_semana` (`carrera_jugador_ui_p1.gd:156-233`):

1. Entreno de la semana (`carrera.entrenar`), si no se hizo al abrir el partido.
2. Si el partido se jugó (motor o «Los Momentos»): se arma un `Partido` con el marcador y se llama a `m.avanzar_semana(p)` (**la semana del mundo avanza aquí**: `semana += 1` en `mundo_p5.gd:52`); **después** `carrera.tras_partido(m, res)` (líneas 175-176).
3. Si se simuló: `m.avanzar_semana(copa_p)` simula la jornada con tu futbolista dentro de su club; se deducen sus goles por diferencia y, **después**, `carrera.tras_partido` (líneas 193-211).
4. `carrera.semana(m)`: agenda, energía, fama, eventos, ofertas, `CarreraRuta.semana` (freno de fama, talentos, rival, vida, misiones).
5. Si ya no queda liga en ningún país: `carrera.fin_de_temporada(m)`, que llama a `CarreraPremios.cerrar` (premios, trofeos, duelo, brazalete) y archiva la temporada.
6. `Partida.guardar(m, "carrera_jugador")`: **guardado automático cada semana**.

Y al pulsar «Empezar la temporada siguiente», `_nueva_temporada` llama a `mundo.nueva_temporada()` (que cierra copas y continentales pendientes, envejece a todos, retira, vence contratos, sortea de nuevo) y vuelve a guardar.

### 7.3.3 Persistencia

`Partida.instantanea` construye un diccionario de todo el mundo; `Partida.guardar` lo serializa con `JSON.stringify(..., "", false, true)` (sin ordenar claves, precisión completa) y `PartidaArchivo.escribir` lo empaqueta con firma `DIN2`, tamaño, MD5 y deflate, escribe un temporal, lo relee y lo compara byte a byte, rota tres copias (`.bak`, `.bak2`, `.bak3`) y renombra (`partida_archivo.gd:72-114`). Es un diseño de guardado **robusto contra cortes y corrupción del archivo**, y no se le encontraron fallos. Los fallos de persistencia de este capítulo están todos *por encima* del archivo: en qué se guarda y en cómo se vuelve a leer. La carga (`Partida.desde_instantanea`) reconstruye clubes y ligas, y luego llama a `_restaurar_lo_tuyo`, que **sale en seco si no hay club humano** (`partida.gd:98-101`); La Ruta se restaura aparte (`partida.gd:389-391`).

La versión de guardado es la 2 (`partida_p1.gd:26`) y la migración (`PartidaArchivo.migrar`) solo sabe de cambios de envoltorio; todo lo añadido desde entonces se maneja con valores por omisión al leer (`d.get(clave, defecto)`), que es una estrategia aceptable mientras la lectura no rechace los datos válidos, que es justo lo que ocurre en G-01.

### 7.3.4 Menús

`Principal` es un `Control` de 17 capas por herencia (`principal_p1.gd` … `principal.gd`) con ayudantes en `ui/principal/` (62 scripts, ~6.350 líneas). Los menús laterales se describen como datos en `MenusLaterales.MENUS` y se pintan con `PantallaMenu`; desde el 15-11 `MenuGuardado` conserva hasta tres menús ya armados fuera del árbol y los reutiliza si su «huella» (mundo, fecha, idioma, tamaño, datos de portada) no cambió. Las noticias del mundo las conecta `_PrincipalNoticias.conectar()`, llamada al cargar, al cambiar de club y al deshacer.

---

## 7.4 Tabla de hallazgos

Prefijos: **R** = La Ruta; **G** = gestión, mundo simulado y guardado; **M** = menús e interfaz general; **V** = visor 3D. Las rutas son relativas a `dinastia-godot/`.

| Id | Grav. | Archivo:línea | Descripción | Escenario concreto | Arreglo propuesto | Veredicto |
|---|---|---|---|---|---|---|
| R-01 | Crítica | `nucleo/partido_despedida.gd:29`, `nucleo/mundo_p7_p1.gd:54-58`, `nucleo/mundo_p6.gd:302-318`, `nucleo/carrera_jugador_p1.gd:80-85`, `ui/carrera_jugador.gd:9-11` | El cierre de temporada del mundo retira (35+ con 40 %, 38 seguro) o deja libre (contrato vencido, 12 % sin renovar) a tu futbolista; `jugador()` solo busca en plantillas y devuelve `null`; La Ruta cae a «crear jugador» y se guarda así. | Termina una temporada con 37 años sin haber anunciado el retiro (`toca_retirarse` exige 38) → «Empezar la temporada siguiente» → cumple 38 → `se_retira` → fuera del mundo. O: contrato que llega a 0 sin el evento de renovación → `libres`. | Excluir `carrera_jugador.jugador_id` de `se_retira` y de `_vence_contrato` (renovación automática o evento obligatorio), y que `toca_retirarse` mire la edad del año siguiente; `jugador()` debe buscar también en `libres` y la interfaz no debe guardar si `jugador()` es `null`. | CONFIRMADO |
| G-01 | Crítica | `nucleo/carrera_jugador.gd:383-389`, `:403` | `_stats_ok` acepta un valor solo si su tipo es igual al del valor por omisión (`int`); el JSON los devuelve como `float` y se descartan: cada carga pone a 0 `pj`, `titular`, `goles` y `asist` de la temporada (las notas sí se conservan). | Jugar 20 jornadas, salir, «Continuar»: la temporada marca 0 partidos y 0 goles; al cierre, sin «Hombre de hierro», sin «Revelación», con el duelo contra el rival perdido y la temporada archivada con `pj` falso. | Aceptar `TYPE_INT` o `TYPE_FLOAT` y convertir con `int()` (como ya hace `CarreraRuta.asegurar`); añadir al banco una ida y vuelta por `JSON.stringify/parse`, no por diccionario en memoria. | CONFIRMADO [M] |
| R-02 | Alta | `ui/carrera_jugador_ui_p1.gd:175-176`, `:193`, `:211`; `nucleo/carrera_ruta.gd:165-169`, `:234` | `tras_partido` se llama después de `avanzar_semana` (que hace `semana += 1`); `retos()` ve otra semana, sortea los retos de la próxima y los juzga con este partido. Los retos mostrados antes del partido nunca se juzgan. | Semana 10: la tarjeta pide «Haz tres paradas». Paras cuatro: no cuenta. En la semana 11 aparecen retos ya marcados ✔ antes de jugar. | Anotar el partido antes de avanzar el mundo, o pasar a `tras_partido` la semana absoluta del partido y usarla en `retos()`; prueba que juegue una semana por la interfaz. | CONFIRMADO |
| R-03 | Alta | `nucleo/carrera_premios.gd:36-38`, `:122`; `nucleo/jugador.gd:305-308` | `_nota_de(o)` devuelve 0 si `o.notas.size() < 10` y `_mejor_del_mundo` exige `>= 20`, pero `Jugador.anotar_nota` recorta el historial a 8. Ningún rival compite: «Jugador del año del club», «Mejor jugador de la liga», «Mejor portero de la liga», «Mejor del mundo», «MVP de copa» y «MVP continental» se ganan solo con el umbral propio. | Delantero con 15 partidos y 7,0 de media en una liga donde otro tiene 7,8: gana «Mejor jugador de la liga» (+220 XP, +6 fama). | Llevar la media de la temporada en un acumulador propio de `Jugador` (suma y cuenta, reiniciado en `nueva_temporada`) y comparar con él; bajar los mínimos a partidos jugados, no a notas guardadas. | CONFIRMADO |
| G-02 | Alta | `nucleo/jugador.gd:119`; `nucleo/carrera_jugador.gd:225`; `nucleo/mundo_p7_p1.gd:38-40`; `nucleo/partido_p2.gd:253-256` | `Jugador.asistencias` solo lo incrementa la carrera; el partido simulado elige asistente (solo para la señal `gol`, «puramente cosmético») y no lo acredita. Además no se reinicia por temporada (goles y partidos sí). | La ficha de cualquier jugador muestra «0 asistencias» en el modo entrenador; en La Ruta el premio «Máximo asistidor» se gana con 6 asistencias y el rival del duelo nunca suma asistencias. El historial por temporada guarda asistencias acumuladas. | Acreditar `asistente.asistencias += 1` donde se emite `gol` en el simulado; reiniciar `asistencias` junto a `goles` en `nueva_temporada`. | CONFIRMADO |
| G-03 | Alta | `nucleo/partida.gd:98-101`, `:251-271`; `nucleo/partida_p1.gd:377`; `nucleo/mundo_p7_p1.gd:150` | En La Ruta (`mi_club` vacío) los continentales existen desde la 2.ª temporada y se guardan, pero su restauración está dentro de `_restaurar_lo_tuyo`, que retorna antes si no hay club humano. Al cargar, `m.continentales` queda vacío. | Temporada 3, tu club va por cuartos de la continental; sales y entras: el torneo ha desaparecido, no hay campeón ni Mundial de Clubes el año siguiente, y «MVP continental» es imposible. | Sacar la reconstrucción de continentales (y `peso_premio`, `sede` de la copa) fuera de `_restaurar_lo_tuyo`, en `desde_instantanea`. | CONFIRMADO |
| G-04 | Alta | `nucleo/mundo_p5.gd:154-171` | `_semana_entrenamiento` sale si `mi_club()` es `null`, y dentro está `procesar_ajeno` para todos los demás clubes. En La Ruta el mundo entero no progresa semanalmente; solo el salto anual (0-2 a los ≤20 años), mientras el potencial se gasta 0-2 por año de los 19 a los 26. | A las cinco temporadas, las promesas rivales han crecido mucho menos que en el modo entrenador; tu futbolista entrena cada semana y los rivales no: el rival del duelo y los premios se vuelven fáciles. | Separar el bucle del mundo de la rama de tu club: que el resto entrene aunque no haya club humano (y crear `Entrenamiento` en La Ruta o hacer `procesar_ajeno` estático). | CONFIRMADO |
| R-04 | Media | `nucleo/carrera_premios.gd:71`; `nucleo/carrera_jugador.gd:8`, `:221`, `:241` | «Guante de la liga — Diez porterías a cero o más» usa `vallas_invictas`, que es un contador de **carrera** (no se reinicia en `fin_de_temporada`). | Portero con 10 porterías a cero acumuladas: gana el premio todas las temporadas siguientes aunque juegue tres partidos. | Contador por temporada en `stats_temp` (o restar el valor al empezar la temporada). | CONFIRMADO |
| R-05 | Media | `ui/carrera_jugador_ui_p1.gd:184-211`; `nucleo/partido.gd:344-346`; `nucleo/carrera_jugador.gd:226-227`; `nucleo/carrera_jugador_p1.gd:150-163` | Simulado y titular: si estás en el once del club, el partido simulado ya te anota nota y partido, y `tras_partido` lo hace otra vez (doble `partidos`, dos notas por partido). Si `es_titular()` te da titular por su propio criterio pero el once automático no te incluye, no juegas en el simulado y tus goles son siempre 0. | Simular una temporada: la ficha del mundo muestra el doble de partidos; un juvenil con buena relación con el DT «titular» no marca nunca en simulado. | Que `es_titular` y el once del club sean la misma decisión (forzar al futbolista en el once antes de simular, como `once_para_partido`) y no volver a anotar lo que el simulado ya anotó. | CONFIRMADO (doble anotación) / PLAUSIBLE (goles 0) |
| R-06 | Media | `nucleo/carrera_jugador.gd:88-106` | La cesión es un traspaso permanente: «a préstamo hasta final de temporada» pero sin registro de vuelta; tampoco reinicia `pj_llegada`, así que `asentado()` cree que llevas tiempo en el club nuevo. Si no hay club candidato, la decisión se consume sin efecto. | Aceptas la cesión en marzo: nunca vuelves; a la semana siguiente ya pueden llegar ofertas de otros clubes. | Registrar la cesión en `Cesiones` (que ya sabe devolver jugadores en `nueva_temporada`) y fijar `ruta["pj_llegada"]`; si no hay destino, no ofrecer el evento. | CONFIRMADO |
| R-07 | Media | `nucleo/carrera_ruta.gd:350-356`; `ui/carrera_jugador_ui_p1.gd:224-230`; `nucleo/carrera_premios.gd:202`, `:208`; `nucleo/carrera_ruta.gd:439` | El freno semanal de la fama (de lo que sube, queda una parte; 12 % si tienes 80+) se aplica también a la fama de los premios de fin de temporada, del duelo y de la selección, porque `fama_ref` se fija antes de `fin_de_temporada`. Las compras de `CarreraVida` sí se excluyen. | Fama 80, ganas «Mejor del mundo» (+10): a la semana siguiente quedas en 81. | Actualizar `fama_ref` tras cada suma que deba quedar entera (premios, duelo, selección), como ya hace `CarreraVida.comprar`. | CONFIRMADO |
| R-08 | Media | `nucleo/carrera_habilidad.gd:21-28`, `:43-44`, `:110-128` | La zona es el promedio de sus sub-habilidades, pero cada sub-habilidad cuesta lo mismo: subir +1 la zona «rit» (2 sub-habilidades) cuesta 2 puntos; «fis» 4; «def» 5; «tir», «pas», «reg» 6. Las zonas de portero no tienen detalle: +1 por punto. | Con los 6 puntos de un nivel, un portero sube 6 puntos de atributo; un delantero, 1 de tiro. | Coste por punto de **zona** (no de sub-habilidad), o pesos de sub-habilidad que sumen 1 en cada zona; detalle propio para el portero. | CONFIRMADO |
| R-09 | Media | `ui/carrera_jugador_ui_p1.gd:229-230`; `nucleo/carrera_premios.gd:127-150`; `nucleo/cierre_torneos.gd:11-40`; `nucleo/mundo_p7_p1.gd:15` | La Ruta cierra tu temporada (premios, trofeos) en cuanto acaban las ligas; la copa y los continentales pendientes se terminan después, dentro de `nueva_temporada` → `CierreTorneos`. Un título ganado en esas rondas no cuenta para tu temporada (ni para la siguiente: ya hay copa nueva). | Mundo con ligas cortas: la final de copa queda pendiente; tu club la gana en el cierre; tu resumen no la incluye. | Llamar a `CierreTorneos.cerrar_pendientes(m)` antes de `carrera.fin_de_temporada(m)` (es idempotente). | PLAUSIBLE |
| V-01 | Media | `visor/gala_premio3d.gd:69`; `visor/calidad.gd:365-368` | La gala fija el atlas de sombras direccionales **global** del renderizador a 4096 y no lo restaura; `Calidad` solo lo vuelve a poner (a 2048) en ALTO y ULTRA. En MEDIO, BAJO y MÍNIMO queda en 4096 el resto de la sesión. | En el móvil, cerrar una temporada de La Ruta con un premio y jugar el siguiente partido: el atlas de sombra pesa 4× lo de antes (el dueño midió ~11 ms por la pasada de sombras con 8192 en ULTRA, orden 19 y comentario de `calidad.gd:366`). | Guardar el tamaño anterior y restaurarlo en `_exit_tree` de la gala, o usar solo luces posicionales cuyo atlas es del `SubViewport`. | CONFIRMADO |
| R-10 | Baja | `nucleo/carrera_jugador.gd:172-194`, `:88-106`; `nucleo/carrera_comienzo.gd:53` | El brazalete (`capitan`) se conserva al fichar por otro club o ser cedido; solo `CarreraComienzo.mudar` lo quita, y su propio comentario dice que «el brazalete es de un club». | Capitán en tu club, aceptas una oferta: sigues siendo capitán en el nuevo desde el primer día. | `capitan = false` en `aceptar_oferta` y `_ceder`. | CONFIRMADO |
| R-11 | Baja | `nucleo/carrera_ruta.gd:430-447` | Si al cerrar no hay rival o no jugaste, `cerrar_duelo` retorna antes de quitar la marca `duelo_doble`: la temporada siguiente el duelo vale doble sin haber elegido el pique ese año. | Respondes al rival en redes (marca), te lesionas toda la temporada: el año siguiente, duelo doble gratis. | Mover `quitar_marca("duelo_doble")` y `CarreraDuelo.cierre` antes del `return` temprano. | CONFIRMADO |
| R-12 | Baja | `nucleo/carrera_jugador_p1.gd:338`, `:376-377`, `:388`, `:398`, `:409`, `:425`; `ui/carrera/ruta_hoy.gd:218` | Títulos y textos de eventos se formatean con nombres (club, veterano, rival) antes de traducirse; `RutaHoy` pinta `e["texto"]` sin `Idiomas.t` y depende de `traducir_arbol`, que no encuentra en el diccionario una frase con un nombre ya dentro. | Jugar en inglés: «Un periodista te pregunta si te ves de titular en <club>» sale en castellano. | Guardar plantilla y datos por separado (como ya hace `CarreraRuta._grada`) y traducir al pintar. | PLAUSIBLE |
| R-13 | Baja | `nucleo/carrera_jugador.gd:287-293`; `nucleo/mundo_p2.gd:96-140` | `equipos_seleccion` crea 18-36 jugadores con `m.crear_jugador`, que consume el `Azar` del mundo y el contador de ids; la cabecera de la carrera promete no tocar `Azar` «para no mover la simulación del mundo». | Dos partidas idénticas divergen según si el jugador juega o no los partidos de la selección. | Generar los rivales de paso con el generador propio de la carrera (como el resto de la carrera). | CONFIRMADO |
| R-14 | Baja | `nucleo/carrera_jugador.gd:78-81`, `:172-188`; `nucleo/carrera_comienzo.gd:42-52` | Las ofertas pueden repetirse del mismo club; ni la firma inicial ni el traspaso ni la cesión miran el tope de plantilla (30) ni el cupo de extranjeros de la liga de destino; `LeyesPais.ajustar_once` puede luego dejarte fuera del once del club por cupo mientras `es_titular` te da titular. | Delantero extranjero que ficha por un club italiano al límite del cupo. | Filtrar destinos por `Cantera.TOPE_PLANTEL` y `LeyesPais.motivo_fichaje`; deduplicar ofertas por club. | PLAUSIBLE |
| G-05 | Baja | `nucleo/partida_p1.gd:146-158`; `nucleo/copa.gd:42`, `:150`; `nucleo/mundo_p2.gd:296` | La copa guarda nombre, ronda, vivos, inscritos y campeón, pero no `peso_premio` ni `historial`. Tras cargar, una copa secundaria (Copa de la Liga 0,55; Trofeo de Campeones 0,5) paga el premio entero, y el cuadro de rondas jugadas se vacía. | Inglaterra o Argentina en el año de la copa secundaria: cargar y ganarla da ~1,8-2× el premio previsto. | Guardar y restaurar `peso_premio` y `historial`. | CONFIRMADO |
| G-06 | Baja | `nucleo/finanzas.gd:79-100`; `nucleo/mundo_p1.gd:286-291` | `asistencia()` topa en el 99 % del aforo, pero `taquilla()` multiplica después por el factor de horario (noche de sábado 1,08): hasta un 6,9 % más de entradas que asientos. | Estadio lleno un sábado por la noche: se cobran 10.690 entradas en un aforo de 10.000. | Topar `gente` al aforo después de aplicar el horario. | CONFIRMADO |
| G-07 | Baja | `nucleo/finanzas.gd:288-293` | La proyección anual cuenta 2 cierres de mes por cada 4 partidos en casa; los cierres reales caen cada 4 semanas del **mundo**, cuya temporada dura lo que la liga más larga activa. En una liga corta dentro de un mundo con ligas largas, la proyección (y el Fair Play que la usa con 15 partidos en casa) subestima meses de sueldos y de ingresos. | Primera chilena (30 fechas) con la Premier activa (38 semanas): proyección de 7 meses frente a ~9 cierres reales. | Calcular los meses con la duración real de la temporada del mundo. | PLAUSIBLE |
| G-08 | Baja | `nucleo/premio_mensual.gd:16-26` | El «Jugador del mes» usa las últimas 4 notas sin mirar la temporada; `notas` no se vacía en `nueva_temporada`, así que en la semana 4 pueden ganar jugadores que no han jugado este año. | Primer mes de la temporada 2: gana un lesionado con las notas de mayo. | Filtrar por partidos de la temporada (o vaciar `notas` en `nueva_temporada`). | CONFIRMADO |
| M-01 | Baja | `ui/principal/noticias.gd:94-97`; `ui/pantallas/pantalla_elegir_club.gd:35` | Al cambiar de club sobre el mismo `Mundo`, `conectar()` vuelve a enganchar una lambda nueva a `mundo.semana_avanzada` (señal del propio `Mundo`, sin candado). Cada cambio añade un `_portada_nueva` diferido más por semana. El efecto visible queda casi anulado porque `_portada_nueva` borra la marca «nueva» en la primera llamada. | Tres cambios de club en la misma partida: cuatro llamadas por semana. | Candado con meta en el `Mundo` como ya tienen `roles` y `eras`. | CONFIRMADO |
| M-02 | Baja | `visor/calidad.gd` (454 líneas); `visor/motor_jugable_p5.gd` (486) | Dos scripts superan las 450 líneas de la norma fija de `CLAUDE.md`; `herramientas/revisar_lineas.py` los señala («pasan de 450 líneas: 2») [M]. | — | Partir con `herramientas/partir_gd.py`. | CONFIRMADO [M] |

**Recuento.** Crítica 2 (R-01, G-01) · Alta 5 (R-02, R-03, G-02, G-03, G-04) · Media 7 (R-04, R-05, R-06, R-07, R-08, R-09, V-01) · Baja 11 (R-10 a R-14, G-05 a G-08, M-01, M-02). CONFIRMADOS 20; PLAUSIBLES 5 (R-09, R-12, R-14, G-07 y la mitad «goles 0» de R-05, que se cuenta con su parte confirmada).

---

## 7.5 Análisis de los hallazgos principales

### 7.5.1 R-01: el mundo puede retirar o soltar a tu futbolista

**Cadena causal.** `Mundo.nueva_temporada` recorre todas las plantillas (`mundo_p7_p1.gd:31-61`). Para cada jugador incrementa la edad, pone a cero partidos y goles, aplica la curva anual y después decide tres salidas: retiro forzado por lesiones (solo para `mi_club_id`, que en La Ruta está vacío), **retiro por edad** (`PartidoDespedida.se_retira`, línea 54) y **contrato vencido** (`_vence_contrato`, línea 57). Ninguna de las tres excluye al jugador de `carrera_jugador`. La regla de retiro es «38 seguro; desde 35, un 40 % por año» (`partido_despedida.gd:7-9`, `:29`), y como la edad ya se ha incrementado cuando se pregunta, un futbolista que termina la temporada con 37 años se retira al empezar la siguiente con probabilidad 1. La Ruta, en cambio, solo ofrece «Colgar las botas» cuando `toca_retirarse` ve 38 años **al cerrar** la temporada (`carrera_jugador.gd:308-310`), es decir, un año demasiado tarde. Entre los 35 y los 37 el riesgo acumulado de que el mundo te retire sin preguntar es 1 − 0,6³ ≈ 78 %.

El contrato tiene el mismo problema por otro camino. El futbolista empieza con `anios_contrato = 2` (`carrera_jugador_p1.gd:126`) y el mundo le resta uno cada temporada (`mundo_p6.gd:303`). Al llegar a cero, como su club es «de la IA» (`c.id != mi_club_id` es siempre cierto en La Ruta), renueva con probabilidad 0,88 (0,5 con 33 años o más) según un hash del id y del año; si no, pasa a `libres` (`:316-318`). La única protección es el evento «La renovación» (`carrera_jugador_p1.gd:356-361`), que solo aparece si sale en el sorteo semanal (45 % de que haya evento, elegido al azar entre todos los posibles y con cinco semanas de espera por evento) y si el jugador elige «Firmas» o «Pides más dinero»; la tercera opción («Esperas ofertas») deja el contrato como estaba.

**Efecto.** `CarreraJugador.jugador()` recorre `m.clubes` y nada más (`carrera_jugador_p1.gd:80-85`). Con el futbolista retirado (fuera de todas las listas) o libre (en `m.libres`), devuelve `null`; `club()` también. `_pintar_semana` interpreta eso como «no hay carrera» y llama a `_pintar_crear()` (`carrera_jugador.gd:9-11`). Para entonces `_nueva_temporada` ya ha llamado a `Partida.guardar(mundo, GUARDADO)` (`carrera_jugador_ui_p1.gd:138-142`), así que la ranura principal contiene una carrera sin futbolista. Las copias `.bak` de `PartidaArchivo` permitirían recuperarla a mano, pero la interfaz no lo ofrece, y en la semana siguiente la rotación de copias sigue avanzando.

**Por qué no lo ve el banco.** Las pruebas de La Ruta crean carreras y avanzan semanas, pero las de larga duración (`sonda_ruta`) miden progresión, no supervivencia del futbolista al cierre de la temporada a los 35-38; y el retiro voluntario se prueba por el camino del evento.

**Arreglo.** Hay tres capas y conviene poner las tres: (1) en el núcleo, `se_retira` y `_vence_contrato` deben devolver «sigue» para el id de la carrera (la carrera decide su retiro, y el contrato se renueva o pasa a ser una decisión obligatoria del jugador); (2) `toca_retirarse` debe mirar la edad que tendrá el año próximo (o retirarse solo por decisión o a una edad máxima explícita de La Ruta); (3) en la interfaz, si `jugador()` es `null` con una carrera existente, mostrar un estado de error recuperable y **no guardar**.

### 7.5.2 G-01: cada carga borra los números de la temporada

**Cadena causal.** `CarreraJugador.a_dic` guarda `stats_temp` tal cual (`carrera_jugador.gd:368`). `Partida.guardar` lo convierte a JSON; `Partida._leer_todo` lo vuelve a leer con `JSON.parse` (`partida_p1.gd:81-86`) y Godot 4.7.2 entrega todos los números como `float` [M]. En la carga, `desde_dic` llama a `_stats_ok(_tipo(d, "stats_temp", c.stats_temp), c.stats_temp)` (línea 403). `_tipo` acepta el diccionario (mismo tipo `Dictionary`), y `_stats_ok` copia cada clave solo si `typeof(v[k]) == typeof(defecto[k])` (línea 387): `pj`, `titular`, `goles` y `asist` valen `0` (entero) por omisión, así que sus valores flotantes se rechazan y quedan a cero; `notas` (un `Array`) sí pasa. La reproducción con el código copiado da exactamente eso [M].

El defensa que se escribió el 4-11 («un guardado dañado o a mano con el tipo equivocado reventaba al cargar») es correcto en su intención y tiene una prueba (`pruebas/auditoria_carrera_limite.gd:185-186`), pero la prueba construye el diccionario en memoria con `{"pj": 3}`, un entero: pasa por un camino que la partida real nunca recorre.

**Efecto.** El resto de la carrera usa `int(d.get(...))` y sobrevive a los flotantes; solo `stats_temp` se pierde. Pero es exactamente lo que alimenta: la nota media se conserva y los contadores no, de modo que tras una carga el futbolista tiene, por ejemplo, «7,1 de media en 0 partidos». Todo lo que se decide con `stats_temp` sale mal: «Revelación» (≥ 15 partidos), «Hombre de hierro» (≥ 30), «Once ideal» (≥ 20), «Goleador del equipo» y de la liga (goles de la temporada), «Máximo asistidor», el duelo con el rival (goles × 3 + asistencias × 2), la propuesta de cesión (titularidades/partidos), el corte del duelo (`pj` ≥ mitad de las jornadas), el trofeo del club (≥ 5 partidos) y la línea de la temporada que se archiva en `temporadas`. Como el juego guarda cada semana y se carga cada vez que se vuelve a La Ruta desde el menú, en la práctica **ninguna temporada jugada en más de una sesión** conserva sus números.

### 7.5.3 R-02: los retos se juzgan contra la semana siguiente

`CarreraRuta.retos()` sortea los tres retos «una vez por semana» y los fija con la semana absoluta `anio × 60 + semana` (`carrera_ruta.gd:165-194`). La tarjeta «Día de partido» los pinta al abrir la semana (`ruta_hoy.gd:115-124`). Pero `_cerrar_semana` llama primero a `m.avanzar_semana(p)` (que termina con `semana += 1`, `mundo_p5.gd:52`) y solo después a `carrera.tras_partido(m, res)` (`carrera_jugador_ui_p1.gd:175-176`; en el simulado, `:193` y `:211`). Dentro, `CarreraRuta.tras_partido` vuelve a pedir `retos(c, m)` (línea 234): la semana ya es otra, `retos_semana` no coincide y se sortea la lista de la semana siguiente, que se juzga con el partido recién jugado y se marca `hecho`.

Consecuencias jugables: los retos que el jugador intentó cumplir no cuentan nunca; los de la semana siguiente aparecen ya resueltos («✔ Marca un gol» antes de jugar); el resumen del partido enseña en `ultimo["retos"]` unos retos que el jugador no había visto. Es el centro del bucle semanal de La Ruta («RETOS DEL PARTIDO … +XP» es la segunda tarjeta de la pantalla principal), así que el fallo no es de equilibrio sino de **credibilidad**: la promesa visible es falsa.

El banco no lo ve porque `pruebas/banco/ruta.gd:29-46` llama a `CarreraRuta.tras_partido` sin avanzar el mundo entre medias. El efecto colateral sobre `ultimo["semana"]` (y el registro de la semana en que se gana un logro, `carrera_logros.gd:83`) es menor.

### 7.5.4 R-03 y G-02: premios que no compiten y asistencias que no existen

`Jugador.anotar_nota` guarda solo las 8 últimas notas (`jugador.gd:305-308`). `CarreraPremios._nota_de` devuelve 0,0 a cualquier jugador con menos de 10 notas (`carrera_premios.gd:36-38`), y `_mejor_del_mundo` descarta a cualquiera con menos de 20 (`:122`). Ambas condiciones son **imposibles**: ningún otro jugador del mundo tiene nunca nota a efectos de estos premios. Por tanto:

| Premio | Condición escrita | Condición real | XP / fama |
|---|---|---|---|
| Jugador del año del club | mejor nota del plantel, ≥ 6,8 | ≥ 10 partidos y ≥ 6,8 | 100 / 3 |
| Mejor jugador de la liga | mejor nota de la liga, ≥ 7,0 | ≥ 15 partidos y ≥ 7,0 | 220 / 6 |
| Mejor portero de la liga | mejor nota de portero, ≥ 6,7 | portero, ≥ 15 partidos y ≥ 6,7 | 170 / 5 |
| Mejor jugador del mundo | nadie con más puntos | ≥ 25 partidos, ≥ 7,5, media ≥ 84 | 400 / 10 |
| MVP de copa / continental | tu club gana y eres el mejor del club | tu club gana y cumples la fila 1 | 160 / 4 · 260 / 7 |

Con la nota media típica de un titular que rinde (7,0-7,5), un buen año da a la vez «mejor del club», «once ideal», «mejor de la liga» y, con media 84, «mejor del mundo»: más de 800 XP en premios que la propia pantalla presenta como únicos de la liga y del planeta. Las galas 3D, que el dueño pidió «únicas por premio y realistas» (orden 55), celebran premios que en el código no se disputan.

`G-02` agrava el cuadro por el lado de las asistencias. El partido simulado elige al asistente de cada gol (`partido_p2.gd:239-256`, ponderado por rol), pero solo para emitirlo en la señal `gol`, documentada como «puramente cosmético» (`partido_p1.gd:22-26`); nadie le suma la asistencia. La única suma de todo el proyecto está en `CarreraJugador.tras_partido` (`carrera_jugador.gd:225`). Y `nueva_temporada` reinicia `partidos`, `goles` y `amarillas`, no `asistencias` (`mundo_p7_p1.gd:38-40`). Resultado: en el modo entrenador, todas las fichas muestran «%d goles · 0 asistencias» en «Partidos esta temporada» (`ficha_jugador_info.gd:59`); en La Ruta, «Máximo asistidor de la liga» se gana con 6 asistencias, el rival del duelo nunca suma por asistencias (`carrera_ruta.gd:427`) y el historial anual (`jugador.gd:70-71`) guarda asistencias acumuladas en la casilla de la temporada. Que el fallo haya sobrevivido indica que ninguna prueba compara las asistencias por partido del simulado con una referencia, como sí se hace con los goles.

### 7.5.5 G-03 y G-04: el mundo de La Ruta no es el mismo mundo

Dos hallazgos comparten causa: piezas del mundo que se escribieron cuando solo existía el modo entrenador y quedaron atadas a «tu club».

**Continentales (G-03).** `_sortear_continentales` se llama sin condiciones en `nueva_temporada` (`mundo_p7_p1.gd:150`) y `_semana_continental` corre para todos (`mundo_p5.gd:216-231`): en La Ruta hay continentales desde la segunda temporada, y `Partida.instantanea` los guarda (`partida_p1.gd:377`). Pero su reconstrucción está al final de `_restaurar_lo_tuyo` (`partida.gd:251-271`), y esa función retorna en la línea 100 cuando `m.mi_club()` es `null`. Al cargar, `m.continentales` queda como lo dejó `Mundo.new()`: vacío. El torneo en curso desaparece, `FifaClubes.sumar(self, previos)` recibe un diccionario vacío en la temporada siguiente (sin Mundial de Clubes ni Intercontinental) y `CarreraPremios.trofeos` nunca encuentra un campeón continental. El mismo camino hace que en La Ruta no se restauren `copa.sede_final_id` ni `ajustes_competicion`.

**Entrenamiento del mundo (G-04).** `ProgresoJugador` documenta que la progresión del mundo está calibrada como **suma** de una parte semanal (`prob_semanal`, ~30 semanas al año) y una anual (`cantera_progreso.gd:3-11`): «por separado parecían prudentes; sumadas…». La semanal solo la llama `Entrenamiento.procesar_ajeno` (`entrenamiento_p2.gd:225-241`), y esta solo se llama desde `_semana_entrenamiento`, que sale en la primera línea si no hay club humano (`mundo_p5.gd:155-156`); además, en La Ruta `entrenamiento` ni siquiera existe (se crea en `tomar_el_mando`, `mundo_p2.gd:342`). La parte anual sigue: +0-2 a los ≤ 20 años, +0-1 de 21 a 24, el potencial se gasta 0-2 por año de los 19 a los 26, y los veteranos bajan desde los 30. Sin la semanal, el saldo del mundo en La Ruta es **negativo**: la media de las ligas cae temporada a temporada mientras tu futbolista entrena cada semana con probabilidades de 0,15-0,60 por semana (`carrera_jugador_p1.gd:232-235`). Esto distorsiona justo lo que La Ruta usa para dar sentido al progreso: el rival «un poco mejor que tú» (`carrera_ruta.gd:397`), la convocatoria a la selección (los mejores de tu país en tu línea, `carrera_jugador_p1.gd:256-262`) y los umbrales de los premios. Lo marco CONFIRMADO porque el camino de código es inequívoco; su magnitud exacta debe medirse con `sonda_ruta` (media de los 100 mejores del mundo por temporada, con y sin el arreglo).

### 7.5.6 R-05: el simulado anota dos veces o ninguna

En el camino simulado, `_cerrar_semana` guarda `j.goles` antes de `m.avanzar_semana`, deduce los goles por diferencia, los resta y deja que `tras_partido` los vuelva a sumar (`carrera_jugador_ui_p1.gd:184-211`). Con los goles el truco funciona; con los partidos y las notas no: si el futbolista estaba en el once del club, `Partido._cerrar_notas_gd` ya le hizo `anotar_nota` y `partidos += 1` (`partido.gd:344-346`), y `tras_partido` lo repite (`carrera_jugador.gd:226-227`). La ficha del mundo cuenta dos partidos por semana y la lista de notas mezcla la nota del motor y la de la fórmula de la carrera (que no son la misma).

El caso contrario es más sutil. `es_titular` decide con su propia regla (media en el puesto + relación con el DT + energía contra el número de rivales en la línea, `carrera_jugador_p1.gd:150-163`), mientras el partido simulado usa el once automático del club (`club.gd:149-167`, por valoración). Si la carrera te declara titular y el once no te incluye, en el simulado no estás en el campo: `j.goles - goles_antes` es siempre 0, y la nota sale solo de la fórmula. `once_para_partido` (`carrera_jugador_p1.gd:167-183`) existe precisamente para meterte en el once, pero solo lo usa el partido jugable. Queda PLAUSIBLE porque su frecuencia depende de cómo de distintas sean las dos reglas en la práctica.

### 7.5.7 V-01: la gala deja la sombra en «4K» para siempre

La orden 55 del dueño pide entregas de premios «realistas y optimizadas», y el 14-11 añadió que durante esas escenas la calidad vaya al máximo «aunque los gráficos estén en mínimo». `GalaPremio3D._calidad_maxima` lo cumple con ajustes del `SubViewport` propio (resolución ×2, MSAA 8×, FXAA, atlas posicional 4096, sin LOD), que mueren con él, y con **una** llamada global: `RenderingServer.directional_shadow_atlas_set_size(4096, true)` (`gala_premio3d.gd:69`). Esa llamada cambia el atlas de sombras direccionales de todo el renderizador. `Calidad.aplicar_viewport` solo vuelve a fijarlo en ALTO y ULTRA (a 2048, `calidad.gd:365-368`); en MEDIO, BAJO y MÍNIMO no lo toca. Tras ver una sola gala en un móvil en calidad baja, el siguiente partido se dibuja con un atlas 4096² (64 MB de profundidad a 32 bits frente a 16 MB a 2048²) [E]. Es exactamente el tipo de regresión que la orden 22 (5 FPS en MEDIA en el teléfono del dueño) obliga a evitar.

### 7.5.8 Hallazgos de equilibrio de La Ruta (R-04, R-07, R-08)

Estos tres no rompen el estado, pero hacen que las cifras que el jugador ve no signifiquen lo que dicen:

- **R-04.** «Guante de la liga» es un premio anual que lee un contador de carrera. Desde que un portero acumula 10 porterías a cero, lo gana cada temporada.
- **R-07.** La fama de los premios se «frena» como si fuera fama normal. Con fama 80 (`parte = max(0,12; 1 − 80/90)`, `carrera_ruta.gd:352`), de +10 de «Mejor del mundo» se queda +1; de +3 del duelo, +1 (el mínimo). `CarreraVida.comprar` evita el freno a propósito (`carrera_vida.gd:175-176`), lo que demuestra que la exención era la intención.
- **R-08.** Ver §7.6.3.

### 7.5.9 Gestión del club: lo que está bien y lo que no

La gestión del club resistió mejor que La Ruta, y eso merece constar. La economía semanal y mensual (`Finanzas`) está explícitamente protegida contra los errores clásicos de unidades (comentario de `finanzas.gd:213-221`: sueldos semanales × 4, ingresos mensuales una vez por mes), la proyección anual no cobra (`_base()` sin efectos), las ventas con porcentaje futuro rechazan montos negativos (`cesiones_p2.gd:233`, «A4-GES-008»), la multa por plantel fuera de cupo respeta la decisión del dueño de no multar con el mercado cerrado (`federacion_p2.gd:153-155`, orden 49) y el contrato de un cedido lo decide su dueño (A4-GES-009). El guardado es atómico, con huella y copias rotativas, y la carga rechaza versiones futuras y guardados sin claves imprescindibles. Los fallos encontrados en esta zona son de menor gravedad: el premio entero de una copa secundaria tras cargar (G-05), entradas por encima del aforo con el horario nocturno (G-06), una proyección de meses que no coincide con los cierres reales en mundos con ligas de distinta duración (G-07) y el «Jugador del mes» que puede leer notas de la temporada anterior (G-08).

### 7.5.10 Menús

En los menús no se encontraron nodos sin liberar: los `remove_child` muestreados van seguidos de `queue_free`, salvo los que mueven nodos a propósito (`PantallaMenu` al ampliar, `MenuGuardado` al guardar fuera del árbol, que libera con `free()` al expulsar de la caché y al vaciarla con `tree_exiting`). La regla de memoria del menú se cumple en lo muestreado: `vistas_menu.gd` usa `CargaCiudad.de("…")` y reconoce `PcOficina` por `get_global_name()` sin nombrarla; `avance_semana.gd` nombra `UsuarioEn3D` y `PendienteClub`, pero son contenedores de 7 y 17 líneas sin dependencias 3D. El único fallo confirmado es M-01 (una lambda duplicada por cambio de club, de efecto casi nulo) y la infracción de la norma de 450 líneas en dos scripts del visor (M-02).

---

## 7.6 Discusión de diseño: ¿es divertida y coherente la progresión de La Ruta?

### 7.6.1 Lo que La Ruta hace bien

Como diseño, La Ruta es la parte más ambiciosa del juego fuera del partido, y su estructura sigue patrones bien establecidos en los juegos de progresión de personaje:

1. **Un bucle corto con decisión semanal**: elegir foco de entreno, jugar el mini juego del toque, decidir uno de los ~40 eventos posibles, jugar (o simular) y ver retos cumplidos. Cada semana tiene algo que decidir y algo que cobrar.
2. **Un bucle medio de temporada**: el rival del duelo con un corte a mitad de temporada que crea un objetivo («si lo remontas, vale más»), las misiones del capítulo y el cierre con premios y gala.
3. **Un bucle largo de carrera**: siete capítulos de Promesa a Leyenda, nueve talentos en tres ramas, compras permanentes de «Tu vida», logros y palmarés.
4. **Identidad del personaje**: estilo (tres por línea), curva de crecimiento (precoz, constante, tardía) y forma visible de −3 a +3 que mueve la jugabilidad de «Los Momentos».

La separación de responsabilidades es limpia (una clase por sistema, todo el estado en un diccionario) y la mayoría de las funciones son puras o casi: es un núcleo **fácil de equilibrar**, que es lo que más necesita.

### 7.6.2 La curva de experiencia

`xp_para(n) = 150 + 60·n` (`carrera_ruta.gd:123-124`) da una curva cuadrática de experiencia acumulada. Calculada con el código:

| Capítulo | Nivel mínimo | XP acumulada |
|---|---|---|
| Promesa | 1 | 0 |
| Revelación | 4 | 810 |
| Indiscutible | 8 | 2.730 |
| Figura | 13 | 6.480 |
| Estrella | 19 | 12.960 |
| Ídolo | 26 | 23.250 |
| Leyenda | 34 | 38.610 |

Experiencia por semana [E], con las fórmulas de `tras_partido` (`carrera_ruta.gd:231-247`): un titular de 90 minutos con nota 7,0 y sin goles suma 15 + 12 = 27 de base; con un gol y 7,5, 48. Los retos (15-130 cada uno, unos 40 de media, tres por semana) añaden en torno a 30-45 por partido si se cumple uno; la racha multiplica hasta ×1,5; el entreno da 6-16, cada decisión 5. Una semana normal de titular queda en 60-90 XP y una temporada de 38 jornadas en ~2.300-3.400, más premios (60-400 cada uno), trofeos del club (120-300), logros (30-120) y el duelo (80). Con esas cifras, Indiscutible llega al final de la primera temporada, Figura en la segunda o tercera, Estrella hacia la quinta, Ídolo hacia la octava y Leyenda hacia la duodécima, con 29-30 años. Es un arco **bien proporcionado** a una carrera de 17 a 35-37 años: el último capítulo llega en la madurez y no se agota la progresión en la mitad de la vida deportiva.

Dos matices. Primero, esa estimación supone que los retos funcionan; con R-02 se cumplen igual de a menudo (son de la semana siguiente, pero con este partido), así que el ritmo no cambia mucho, pero el jugador **no controla** qué reto cumple: la decisión se pierde. Segundo, con R-03 los premios aportan bastante más de lo previsto (un buen año rinde 600-900 XP en premios automáticos), lo que adelanta los capítulos entre una y dos temporadas en una carrera de éxito.

### 7.6.3 Tres monedas de mejora y sus tipos de cambio

La Ruta tiene **tres** maneras de subir atributos, más el entreno semanal:

1. **Entreno semanal** del foco: probabilidad 0,15 + margen al techo × 0,30 + juventud × 0,12 + agenda, entre 0,08 y 0,60, ×0,4 con poca energía (`carrera_jugador_p1.gd:232-235`). A los 17 años con 26 puntos de margen sale ~0,53 por semana: ~20 puntos de atributo por temporada si todo fuera a un foco, frenado por el tope de 14 sobre la media (`TOPE_SOBRE_MEDIA`).
2. **Puntos de habilidad**: 6 por nivel (`CarreraHabilidad.PUNTOS_POR_NIVEL`). Cada punto de **sub-habilidad** cuesta base × puesto × nivel, con base 1/2/3/5/7 según el valor (< 60, < 70, < 80, < 90, ≥ 90), puesto 1/1,5/2 (clave, útil, ajena) y +5 % por nivel. Calculado con el código: a nivel 1 la escala es 1-2-3-5-7; a nivel 20, 2-4-6-10-14; a nivel 34, 3-6-8-14-19 (zona clave). Una sub-habilidad de 90+ en zona ajena a nivel 34 cuesta 38 puntos.
3. **Puntos de talento**: 1 por nivel y 1 por capítulo completado; cuando ya se aprendieron los nueve talentos, cada punto «pule» **+2 a una zona entera** sin coste creciente, sin techo y sin tope sobre la media (`carrera_talentos.gd:122-141`).

Los tipos de cambio entre estas monedas son incoherentes:

- **Zonas desiguales (R-08).** La zona es el promedio de sus sub-habilidades, pero el coste se paga por sub-habilidad: +1 de zona cuesta 2 puntos en velocidad, 4 en físico, 5 en defensa y 6 en tiro, pase o regate. Velocidad es tres veces más barata que tiro, y no hay razón de diseño escrita para ello.
- **El portero sube seis veces más barato.** Sus seis zonas (`div`, `par`, `saq`, `ref`, `vel`, `pos`, según `datos/tablas.json` → `POSD.POR`) no tienen detalle (`CarreraHabilidad.de_zona` devuelve la zona como única habilidad), así que cada punto es +1 de zona. Con los 6 puntos de un nivel, el portero gana 6 puntos de atributo repartibles en las cuatro zonas con peso ≥ 0,21 (≈ +1,3 de media); el delantero centro, 1 de tiro (+0,39 de media).
- **Pulir domina a nivel alto.** A nivel 20, subir una zona clave de 85 a 86 cuesta 10 puntos por sub-habilidad × 6 = 60 puntos de habilidad (diez niveles). Pulir da +2 a esa zona por 1 punto de talento (un nivel). En la parte alta de la carrera, la única decisión razonable es pulir; los puntos de habilidad pasan a ser casi decorativos.

La recomendación es definir el coste en **puntos de zona** (y que la pantalla de reparto de la orden 51 muestre las sub-habilidades como detalle, no como unidad de compra), dar al portero un detalle propio de 3-4 sub-habilidades por zona, y cobrar el pulido con la misma tabla creciente (o limitarlo por temporada). Así las tres monedas convergen en un único tipo de cambio que el jugador puede aprender.

### 7.6.4 Premios, fama y la sensación de mérito

Conviene distinguir entre recompensas **contingentes** (dependen de lo que hiciste frente a un estándar o frente a otros) y **no contingentes** (llegan por cumplir un umbral propio); un premio que se anuncia como «el mejor de la liga» promete lo primero [E]. La Ruta las planteó contingentes y bien escalonadas (del club a la liga, de la liga al mundo), con una gala 3D distinta para cada una. Con R-03, cuatro de las más valiosas son de hecho no contingentes respecto a los demás: se ganan con un umbral propio. Con R-04, el «Guante» se vuelve permanente. Con R-07, la fama que prometen se evapora. Y con G-01, los umbrales de partidos se incumplen en cuanto el jugador carga la partida. El resultado es el peor de los dos mundos: premios que llegan cuando no deberían y que no llegan cuando sí.

La fama, por su parte, tiene un diseño sensato («cuesta más cuanto más tienes», `carrera_ruta.gd:346-356`), escrito tras medir que un delantero de 18 años llegaba a 100 en su segunda temporada. Pero el freno se aplica a la diferencia semanal sin distinguir su origen; la exención explícita de `CarreraVida.comprar` debería extenderse a toda fama que el juego anuncia con una cifra («+10 de fama»).

### 7.6.5 El rival y el duelo

El rival («un joven de tu línea en tu liga, de otro club y de media parecida», 4 puntos por encima y más cuantos más duelos ganas, `carrera_ruta.gd:383-414`) es una gran idea de bucle medio, con un corte a mitad de temporada que crea tensión narrativa. Sus puntos (goles × 3 + asistencias × 2 + nota × 2) son legibles. Pero hoy es injusto en dos direcciones: las asistencias del rival valen siempre 0 (G-02) y la media de su nota sale de sus 8 últimos partidos mientras la tuya es la de la temporada; y tras una carga tus goles y asistencias de la temporada valen 0 (G-01). Con el mundo sin entrenamiento semanal (G-04), además, el rival «un poco mejor que tú» deja de serlo enseguida, y la búsqueda acaba en el resto del mundo (`fuera`) más a menudo de lo previsto.

### 7.6.6 Coherencia con el mundo

La decisión de que el futbolista sea un `Jugador` más es la correcta y debe conservarse; lo que falta es una **lista explícita de lo que el mundo no puede hacerle sin preguntar**: retirarlo, dejarlo libre, cederlo, cambiarlo de puesto o de dorsal. Hoy esa lista no existe y R-01 es la consecuencia. Del mismo modo, el mundo de La Ruta debería ejecutar todas las fases «del mundo» de `avanzar_semana` aunque no haya club humano (entrenamiento ajeno, al menos), y separar con claridad en el guardado lo que es «del mundo» (continentales, copa, ajustes) de lo que es «de tu club». G-03 y G-04 son dos manifestaciones del mismo acoplamiento.

### 7.6.7 ¿Es divertida?

Con los fallos críticos y altos arreglados, la respuesta del código es sí, con reservas. El bucle semanal tiene decisión, riesgo y recompensa; la progresión está bien espaciada; hay identidad (estilo y curva) y hay antagonista (rival). Las reservas son de **legibilidad**: el jugador ve dos monedas de puntos con nombres parecidos («puntos de talento», «puntos de habilidad»), tres sistemas de botas (el evento «Una marca de botas te llama» de `carrera_jugador_p1.gd:351-355` convive con `CarreraPatrocinio`), dos caminos al brazalete (el evento con fama ≥ 45 y relación ≥ 65, y la tirada de fin de temporada con su probabilidad) y unos retos que no se juzgan cuando se ven. Ninguna de estas cosas se nota en una prueba automática y todas se notan en la primera hora de juego. El capítulo 9 debería incluir, para La Ruta, una prueba de juego guiada de tres temporadas con un cuestionario corto sobre comprensión de los sistemas, además de la sonda de equilibrio.

---

## 7.7 Por qué las pruebas no vieron estos fallos

El proyecto tiene un banco amplio (más de 30 grupos, orden 26) y pruebas específicas de La Ruta (`pruebas/banco/ruta.gd`, `ruta_premios.gd`, `auditoria_carrera_limite.gd`, `prueba_ruta_idiomas.gd`, `sonda_ruta`). Que los fallos graves hayan pasado tiene tres causas recurrentes, que son en sí mismas un hallazgo de método:

1. **Diccionarios en memoria en vez de ida y vuelta por disco.** La prueba de `stats_temp` incompleto usa `{"pj": 3}` (entero); la ida y vuelta de `ruta.gd:305-306` comprueba nivel, experiencia, ahorros, compras, botas, misiones, retos y rival, pero no `stats_temp`. Ningún test de La Ruta pasa por `JSON.stringify` + `JSON.parse`, que es lo único que distingue un guardado real. **Recomendación**: una utilidad de banco `ida_y_vuelta(m)` que serialice el mundo con la misma llamada que `Partida.guardar` y lo cargue con `desde_instantanea`, y que todas las pruebas de guardado la usen.
2. **Orden de llamadas distinto del de la interfaz.** Las pruebas llaman a `CarreraRuta.tras_partido` sin avanzar el mundo, y a `fin_de_temporada` sin pasar por `nueva_temporada`. **Recomendación**: probar la semana a través de `CarreraJugadorUI._cerrar_semana` (ya se hace en `prueba_carrera_flujo.gd`, pero sin comprobar retos ni premios) y una temporada completa hasta el cierre y el arranque de la siguiente.
3. **Umbrales imposibles que nadie comprueba.** `_nota_de` exige 10 notas a una lista de 8; ninguna prueba verifica que un premio de «el mejor» **no** se otorgue cuando otro jugador lo supera. **Recomendación**: pruebas negativas para cada premio comparativo (montar un rival con mejor cifra y comprobar que no se gana).

A estas se añade la longitud: R-01 solo aparece a partir de los 35 años del futbolista, unas 18 temporadas después de crearlo. Una prueba de larga duración que juegue 22 temporadas simuladas (≈ 840 semanas) es costosa, pero puede aislarse: crear el futbolista con 34 años y cerrar cuatro temporadas.

---

## 7.8 Conclusiones

1. **La Ruta tiene dos fallos que pierden la carrera** (R-01: el mundo retira o deja libre al futbolista; G-01: cada carga borra los números de la temporada). Ambos son baratos de arreglar y deben ir antes que cualquier pulido: no tiene sentido equilibrar premios que se calculan con contadores que se borran al cargar.
2. **Cinco reglas anunciadas al jugador no se cumplen** (retos de la semana siguiente, premios que no compiten, asistencias inexistentes, continentales que desaparecen al cargar, mundo sin entrenamiento semanal en La Ruta). Tres de ellas (G-02, G-03 y G-04) son del mundo y no de La Ruta: G-02 afecta también al modo entrenador.
3. **La gestión del club está en mejor estado**: la economía, el guardado en disco y las reglas de cupo resisten bien; los fallos encontrados ahí son de baja gravedad.
4. **Los menús no presentan fallos de memoria ni de conexiones relevantes** en lo muestreado; la norma de 450 líneas se incumple en dos scripts del visor.
5. **El diseño de progresión de La Ruta es sólido en estructura** (curva, capítulos, bucles corto-medio-largo, rival) y **débil en su economía de puntos**: el coste de mejorar depende de detalles de implementación (número de sub-habilidades, portero sin detalle) y no de una decisión de diseño.
6. **El método de prueba debe cambiar** en dos puntos concretos: ida y vuelta real por JSON en todo lo que se guarda, y pruebas que sigan el orden de la interfaz.

### 7.8.1 Orden de arreglo recomendado

| Orden | Hallazgos | Motivo |
|---|---|---|
| 1 | R-01, G-01 | Pérdida de la carrera o de sus datos. |
| 2 | R-02, R-03, G-02 | Reglas visibles falsas; G-02 también en el modo entrenador. |
| 3 | G-03, G-04 | Coherencia del mundo de La Ruta (requieren medir con `sonda_ruta` antes y después). |
| 4 | V-01 | Regresión de rendimiento en las calidades que prioriza el dueño. |
| 5 | R-04, R-05, R-06, R-07, R-09 | Equilibrio y coherencia de temporada. |
| 6 | R-08 (y §7.6.3) | Rediseño de la economía de puntos: decisión de diseño, conviene pasarla por el dueño (sección «PREGUNTAS PARA EL DUEÑO» del plan, orden 44). |
| 7 | Bajos | En cualquier pasada de limpieza. |

Cada arreglo debe cerrar con el banco en «FIN. 0 fallos» y, para R-01, G-01, R-02 y R-03, con una prueba nueva que habría fallado antes del arreglo (§7.7).

### 7.8.2 Validez del capítulo

Las conclusiones dependen de la lectura del código en el commit indicado y de dos reproducciones mínimas [M]. Los efectos en juego son deducciones; las magnitudes de §7.6 son estimaciones [E] que deben medirse con `sonda_ruta` tras los arreglos. Los cinco hallazgos PLAUSIBLES necesitan una partida concreta (ligas activas, plantillas) para confirmarse o descartarse.
