# PENDIENTES — qué falta, cómo se hará y qué falta fusionar

Documento de traspaso: si la sesión se corta o el contenedor se pierde, desde aquí se retoma.
Última actualización: **19-10-2026**. Se actualiza en cada bloque de trabajo.

> **23-10:** el plan vigente es `MEGAPLAN_REESTRUCTURACION.md` (nueva estructura del juego + estos
> pendientes + limpieza + código menos delicado). HECHO 23-10: colisiones del club a pie
> (`visor/colision_club.gd`: cuerpo entero, muebles con física, personal que se esquiva).

## 0. EN ESPERA desde el 23-10 (decidido por el dueño: PRIMERO el límite de 450 líneas)

El orden es: **1.º partir todos los scripts a ≤ 450 líneas** (`herramientas/revisar_lineas.py`, MEGAPLAN §10.1); lo demás
queda registrado aquí y no se toca hasta terminar eso.

| Pendiente | Detalle | Qué hace falta |
|---|---|---|
| Reescribir la historia (real) | Ensayo hecho: 1,33 GiB → 804 MiB, árbol idéntico (`herramientas/reescribir_historia.py`, MEGAPLAN §10.2) | «sí, empuja» del dueño; antes: fusionar la rama a `main` (PR que él pida) y correr el banco en un clon limpio; después GitHub puede pedir limpieza de `refs/pull` |
| LFS | Se queda como está: los originales (`docs/lfs_fuera_del_juego.csv`, 1,77 GB) SOLO existen en GitHub | nada; opcional: copia propia con `git lfs fetch --all` (gasta cuota de descarga) y quitar los 67 archivos (108 MB) con copia idéntica en el juego |
| Fase 0 «de verdad» | Extraer responsabilidades de `principal.gd` a clases con su propia interfaz (MEGAPLAN §7.1), prueba de colisiones al banco, partir `banco.gd` | tras el límite de 450 |
| Reloj único, necesidades, casa y familia, personas en persona | MEGAPLAN §3.3 | tras la fase 0 |
| Fases 1-6 de la reestructuración | intro ≤ 5 s, idioma, menú inicial fases 1-5, prólogo 3D, oficina con PC, vida en 3D (MEGAPLAN §3 y §8) | esperar al dueño (estaba previsto para la semana del 26-10) |
| Fase 4 (entrada al campeonato) | cifras propuestas en MEGAPLAN §9.1 | que el dueño las valide |
| Banderas y monumentos del globo | la red del entorno bloquea Wikimedia | el dueño abre «Network access» (`upload.wikimedia.org`, `commons.wikimedia.org`, `en/es.wikipedia.org`, `flagcdn.com`) |
| Azure/Foundry (200 USD, 30 días) | analizado en el chat, sin decidir | verificar cuota del modelo en Foundry |
| Traducir 523 frases descriptivas | siguen en castellano en los otros 8 idiomas (`docs/textos_sin_traducir.txt`) | contenido: ~4.000 traducciones; priorizar mejoras de instalaciones y logros |
| `estres_menus.tscn` | no termina en modo sin pantalla | ver si ya pasaba antes del reparto |
| Zonas de la ciudad fuera del club | colisiones con otro sistema (`ExploradorCiudad._choca_circulos`), no revisado a fondo | caza visual |

## 1. Qué falta por FUSIONAR

| Qué | Dónde está | Estado | Cómo se fusiona |
|---|---|---|---|
| Todo lo hecho del 14 al 17-10 | `main` | **FUSIONADO el 17-10 con el PR #7** | nada pendiente; lo nuevo que se haga va en la rama y se pasa con otro PR cuando el dueño lo pida |
| Tanda 2 del TOP 25, mejoras del coche/GPS y caza de bugs del 17-10 | `main` | **fusionado el 17-10 con el PR #8** (pedido del dueño) | nada pendiente |
| Línea defensiva (M-123), notas de partidos mirados, prueba del bono, física M-114/115, tope de aceleración, ojos de lejos, guardado seguro, física en el banco, fueras del acta, repetición manual (19/20-10) | rama `ccr-54306f57-jlcywg` | **PR abierto el 20-10** (pedido del dueño) | fusionarlo |

## 1.b Hecho en la última tanda (17-10, ya en la rama)
GPS 2D estilo GTA (`ui/componentes/minimapa_ciudad.gd`: gira con el rumbo, ruta morada al estadio,
marcas de estadio y casa, N; M lo esconde), cámara de persecución del coche (retraso en curvas, FOV con
la velocidad) y primera persona con cabina 3D (`ExploradorCiudad._cabina_3d`); D-pad táctil solo en
pantallas táctiles. Velocímetro de la cabina movido a la consola y brazos del conductor que giran el volante (17-10). El minimapa dibuja también las calles del núcleo y, dentro de él, la ruta va directa al estadio (17-10).

## 2. Qué falta HACER (por orden) y CÓMO

Fuente completa: `ESTADO_MEJORAS.md` (470 puntos con su estado + TOP 25) y `COMPARACION_JUEGOS_2.md`.

### 2.1 Del TOP 25 que queda
| Id | Qué | Cómo |
|---|---|---|
| M-057 | Fabricantes de ropa inventados con logo por club | lista de marcas ficticias + logo procedural; uniform en `equipacion_q.gdshader` (hoy una sola «ala») |
| ~~M-123~~ | HECHO 19-10: línea defensiva común y trampa | `MotorJugable._linea_defensiva` (recula si el portador está libre, sube si está presionado o el balón va atrás; con la trampa sube más). Sonda (simetría, 12 partidos cortos): goles 1,83→1,50, tiros 9,7→8,5, fueras 0,8→1,2, pases 76→77 %. Con `TRAMPA=1` el rival cae en fuera de juego 0,42→0,75 por partido. `SIN_LINEA=1` vuelve a la defensa de antes (para comparar) |
| ~~M-114/115~~ | HECHO 19-10 (casi): giros y saltos | Sonda de física (600 fotogramas de juego, ya sin la ceremonia): jugadores > 10,5 m/s 789 → 0 (eran los saques: se colocaban patinando a 22 m/s; ahora la ayuda completa hasta 9 m/s y el saque espera a que estén colocados, máx. 3 s), giros > 720°/s 3 → 0 (`_mirar`: al patear y en filigranas giran a ≈690°/s), balón saltando en juego 3 → 1 (conducción que recoge el balón en vez de teletransportarlo; atajada sin salto a las manos). Y 19-10 (2.ª pasada): TOPE DE ACELERACIÓN TOTAL `MotorJugable.A_MAX` = 18 m/s² (×1,35 con giro firme) y ayuda del saque suave. Tirones > 30 m/s²: ≈57 en 300 fotogramas → 15 en 600. Con 14 m/s² los goles caían a la mitad (0,75 vs 1,5 por partido): descartado; con 18, 1,33 goles y el mejor gana 10 de 16 (sonda `A_MAX=` para probar otros). La sonda ya separa > 15 (lo que permite el tope) de > 25 (tirones) |
| M-263 | Semana con agenda en la Carrera de Jugador | calendario entreno/descanso/vida social entre partidos en `carrera_jugador.gd` |
| M-040 | Gente del club y de la ciudad en primeras filas | reutilizar `PeatonQ` horneados en las 2 primeras filas (`StadiumBuilder._montar_horneados`) |
| M-033 | Variedad de ropa y pelo en hinchas | más variantes horneadas (`herramientas/hornear_publico.gd`) |
| ~~M-036/044~~ | HECHO 20-10: la ola y la onda | `hinchada.gdshader` (`ola_*`, `onda_*`) + `visor/ola_grada.gd` (escribe el reloj en el material mientras dura y lo apaga). Onda en cada gol local (DT y Carrera) desde ese fondo; la ola, una vez por partido como mucho (35 % de los partidos entre el 58' y el 82', o con dos goles de diferencia pasado el 62'). Sin vértices ni llamadas de más. Prueba `_probar_ola_grada`, captura `captura_ola.tscn` |
| ~~M-132~~ | HECHO 20-10: repetición manual de los últimos 10 s | tecla G / Share (`jugar_repeticion`), botón «⟲ Repetición» en la pausa y fila en el panel de controles (`VistaEstadio.repetir_jugada`) |
| M-173 | Sonido del motor del coche con RPM y radio con sonidos propios | `AudioStreamGenerator` o muestras propias; sin música con licencia |
| M-130/152 | Modo práctica de controles FC | campo vacío con el motor y retos por combinación |

### 2.2 De la comparación con otros juegos (`COMPARACION_JUEGOS_2.md`)
- **Roles por jugador** (como los PlayStyles de FC 26) con efecto en el motor.
- **Línea defensiva** (= M-123).
- **Radio del coche** (= M-173).
- Narración por voz: 🔒 dueño (audios).

### 2.3 Detectados en las últimas pruebas (no están en el informe)
- ~~**Penales**: entraban ~9 de 10~~ HECHO 17-10: portero que acierta el lado para más y algún tiro se va fuera (~3 de cada 4 por cálculo; medir con más tandas si se nota).
- ~~**Añadido**~~ HECHO 17-10: suma 45 s por gol y 30 s por cambio o expulsión, con tope (`MotorJugable._sumar_anadido`).
- ~~**Once automático de la IA**: delanteros de lateral~~ HECHO 17-10: fuera de su puesto nadie rinde más que su media y cambiar de línea cuesta más (`Club.once`); el juvenil obligatorio (CHI/BOL) entra por alguien de su línea (`LeyesPais.ajustar_once`). Ojo: el prototipo `MotorLibre` (no usado por el juego) da ~7,6 goles de media con onces bien armados.
- ~~**Notas de los partidos mirados**~~ HECHO 19-10: `Partido.cerrar_notas_mirado()` (desde `Mundo.avanzar_semana`), una vez, con la nota de `valoraciones()` y sin tocar el `Azar`.
- ~~**Cambio con cartel y palmada** en la Carrera de Jugador~~ HECHO 20-10: la misma `EscenaCambio` del DT (`PartidoJugable._escena_cambio`, con `MotorJugable.ultimo_cambio`); el nodo del que sale se esconde, no se borra, y si el que entra eres tú no se te retiene. Prueba en `prueba_carrera_flujo` («CAMBIO … OK»).
- ~~**Prueba frágil** `_probar_motor_libre` («bono del club»)~~ 19-10: con +20 % el efecto quedaba bajo el ruido de 12 partidos; ahora prueba la dirección con +35 %.
- **Optimización** (19-10, cifras CORREGIDAS): `medir_partido` medía la CEREMONIA (alineaciones), no el juego; ya la salta. En juego real con la cámara de TV (ALTO, Forward+): **532 llamadas y 1,34 M triángulos** (no 0,76 M). HECHO: ojos solo hasta 35 m (`VestidorQ.DIST_OJOS`) → 493 llamadas (−7 %), sin diferencia visible en la toma de TV (de cerca sí harían falta: la cuenca queda clara). Probado y descartado: butacas cercanas livianas (`LIVIANAS=1`): no bajan los triángulos (desde la TV casi no se ven). Reparto medido (ocultando grupos): público ≈180 mil, sombras ≈156 mil tris y ≈120 llamadas, cabezas/pelo ≈100 mil, cuerpos ≈67 mil; ≈830 mil sin dueño. `POR_HIJOS=1` NO sirve tal cual: el partido sigue y la cámara se mueve, así que la base de un solo fotograma no compara (salieron 700 mil por piezas pequeñas). CÓMO HACERLO BIEN: congelar motor y cámara (`set_physics_process(false)` en el motor y el rig) antes de recorrer las partes, y medir cada una en ese mismo fotograma. Pendiente: averiguar qué pone los 1,34 M en pantalla (cuerpos SuperHero ~12,5 mil por jugador, público) y si `CaraReal` puede tener un corte de lejos sin dejar la cara hundida.
- **Red del arco**: onda más ancha y lenta (17-10), techo sin asomar por el larguero. **Cartel del cuarto árbitro**: 20-10 a tamaño real (0,92 × 0,62 m), dígitos con halo, mango y por encima de la cabeza. Desde la toma abierta de TV sigue siendo pequeño (como en la tele de verdad, que corta a un primer plano): pendiente un corte de cámara al cartel.

### 2.5 Caza de bugs del 17-10 (estrés pedido por el dueño) — se registra todo al encontrarlo
- ~~Partido dirigido: cerrar el juego perdiendo permitía repetirlo hasta ganar~~ HECHO (`PartidoPendiente`).
- ~~Atravesar paredes con un coche encima o con un tirón de fotogramas~~ HECHO (`_mover_un_trozo`).
- Atropellar peatones: el coche rebota (son obstáculos móviles). No hay daño ni reacción del peatón: sin arreglar (diseño).
- Coches del tráfico y autobús: E no hace nada (no se pueden robar ni subir al bus). Inofensivo; posible mejora.
- Metro: E en marcha = «bajar en la próxima»; no se puede salir en el túnel. Correcto.
- Esc bajo tierra (metro/galería): el entorno se restaura en `_exit_tree`. Correcto.
- IDEAS registradas (el dueño dijo que NO por ahora, 17-10): subir al autobús, tomar coches del tráfico,
  reacción del peatón al atropello.
- **MENÚS A VELOCIDAD SOBREHUMANA** (`pruebas/estres_menus.tscn`, 400 fotogramas, 2-6 acciones por fotograma):
  · ~~Pestañas liberadas~~ HECHO: `MenuLateral.abrir_menu` reutilizaba una pantalla que se estaba cerrando
    (fundido de 0,15 s) y le volvía a meter las pestañas, que se borraban con ella. Ahora una pantalla que
    se cierra no coge contenido (`PantallaMenu.cerrando()`). Antes: (se «muda» a una PantallaMenu y se borra con ella):
    luego `get_tab_count` sobre instancia liberada (1001 veces), y el juego queda sin pantallas (1282 → 497 nodos).
  · `_perezoso` (Principal), `pintar` y `PantallaMenu._mudar` reciben nodos ya liberados.
  · ~~`BotonFx` conectado varias veces~~ HECHO: `node_added` salta en cada cambio de padre; ahora marca `_fx`. Antes: «signal already connected» (`_sonar`, `_a`, `_arriba`): se conecta dos veces el mismo botón.

### 2.6 Idea del vídeo que regaló el dueño (20-10): FALTAS POR PUNTOS
Un creador explica cómo decidir la sanción sumando el peso de cada factor de la entrada:
agarrón 1,4 · por detrás 3,0 · empujón 1,7 · a gran velocidad 2,0 · deslizante 2,6 · falta
profesional (último hombre, ocasión clara) 2,3 · de pie 1,2 · carga de hombro 0,9 · agresiva 2,4;
y umbrales falta ≥ 1,0, amarilla ≥ 4,0, roja ≥ 7,0 (ej.: por detrás + a gran velocidad + profesional
= 7,3 → roja). Usa la velocidad de cada jugador y su posición (quién es el último defensor).
Hoy `MotorJugable._falta` decide la tarjeta con una tirada (`prob_tarjeta`) y solo hay roja por
doble amarilla. CÓMO: en `_entrada`/`_duelo_*` sumar factores reales (ángulo de la entrada respecto
a la marcha de la víctima = «por detrás», velocidad del infractor, barrida, ¿era el último defensor
con el arco libre?) y pasar la suma a `_falta`; la roja directa ya tiene `_expulsar`. Pendiente de
que el dueño lo pida.

### 2.7 Hecho el 20-10 (tarde) y lo aprendido
- Faltas por puntos EN EL MOTOR (`MotorJugable.puntos_falta`, `PESO_FALTA`, umbrales 4/7, roja
  directa con motivo en el aviso). Sonda: ≈1 amarilla por ≈4,5 faltas (22 %), rojas raras.
- Mini bancos: `herramientas/mini_banco.sh <grupo|_probar_x>` (GRUPOS en banco.gd). Al correrlos
  sueltos salieron 2 bugs reales: el club empezaba sin bonificaciones hasta la 1.ª semana, y
  contratar personal borraba DT/maestrías/camarín hasta la semana siguiente. Arreglados.
- CLAUDE JUEGA (`pruebas/claude_juega.tscn`, MITADES=1, SEMILLA=n): partido real manejado con el
  mando. Encontró: el contador de pases buenos del jugador contaba 4 de 26 (eran 16 de 28; el mando
  salta al receptor) y el pase asistido ignoraba si la línea estaba tapada. Arreglados. Queda: con
  el ritmo «rápido» hay ~2 remates por equipo en 90' (equilibrio por decidir).
- C++ (medido): el motor del partido gasta 0,7 ms por paso (4 % de un fotograma) y TODO el código del
  partido < 4 ms por fotograma sin dibujar; avanzar una semana ≈ 147 ms (peor 298 ms, 6 ligas).
  El cuello de botella es DIBUJAR (llamadas, triángulos, sombras), que C++ no acelera. Conclusión:
  C++/GDExtension NO compensa hoy; reconsiderarlo solo si simular temporadas enteras se hace lento.

### 2.8 Rendimiento del partido (20-10, medido con promedios de 120 fotogramas)
- OJO: en este entorno el número de triángulos de UN fotograma salta entre 0,7 y 1,4 M aunque todo
  esté en pausa (`ESTABILIDAD=1`): solo valen promedios (`medir_partido` normal + `OCULTAR=`).
- Reparto de llamadas (base 504): mascota de la banda −106, vallas LED −80, fachada −21; guiños y
  marcador ≈0. HECHO: mascota fundida por material y parte (`MascotaQ.fusionar`, se ve igual:
  capturas `mascotas*.jpg`) → 450; cajas de las vallas sin sombra propia → **432 (−14 %)**.
- HECHO: las 36 cajas de las vallas en 2 `MultiMesh` con color/brillo por instancia
  (`VallasLed._montar_multimesh`, prueba `_probar_vallas_led`) → **419 (−17 % desde 504)**.
- Medido (`SIN_GENTE_FUERA=1`): las 34 personas fuera del campo cuestan 65 llamadas y ~100 mil
  triángulos (~2 por persona: ya es poco; bajar más = quitar gente o sombras, se notaría).
- Siguiente candidato: los 36 rótulos `Label3D` de las vallas (una llamada cada uno): un solo
  `SubViewport` con todo el anillo de texto, o un atlas de anuncios en la textura de la caja.

### 2.9 Más chispa en el partido (20-10, pedido del dueño)
- Diagnóstico (`ESCENARIO=diag`, ahora con saques por tipo): 19 % del tiempo en saques (1,6-2,2 s
  cada uno), 24 % del juego con el balón en el aire, ~20 % en el último tercio, ~0,8 tiros por
  minuto y equipo (FC ≈ 1,5).
- HECHO: sorteo de tiro menos conservador (`CHISPA_TIRO` 0,24 → 0,16) y saques de banda/puerta
  rápidos que no esperan a todos. Medido con 48 partidos por versión (¡con 18 el ruido es ±25 %!):
  tiros 7,9 → 8,7 (+10 %), goles 1,06 → 1,23, pases igual (~73 %); el mejor sigue ganando.
- Probado y DESCARTADO: más peso al pase que avanza (`CHISPA_AVANCE` 0,12: más tiros pero peores,
  menos goles) y decidir antes (`CHISPA_PAUSA` 0,7: menos tiros). Quedan como variables de la sonda.
- HECHO (20-10, tarde): LLEGADA AL ÁREA (`MotorJugable._zona_de_llegada`): con el balón de un
  compañero a menos de 32 m del arco, el 9 va al primer palo o al punto de penal, el extremo del
  lado contrario al segundo palo y el medio más adelantado a la frontal. 48 partidos con/sin:
  goles 1,23 → 1,56 (+27 %), tiros 8,7 → 9,4, pases ~72 %; el mejor gana 14 de 24 y pierde 3.
  Desde antes de la chispa: goles 1,06 → 1,56 (+47 %). `SIN_LLEGADA=1` para comparar.
- El techo real (antes de la llegada): llegar al área. Con el ritmo «rápido» (4 min reales) salen ~6 tiros en total.
  Siguiente paso, si el dueño quiere: más desmarques de ruptura y apoyos en el último tercio
  (jugadas prehechas) — rediseño de IA, recalibrar con 48+ partidos por cambio.
- Control de física en el banco cazó al instante un exceso (>10,5 m/s) de los saques rápidos:
  arreglado (la ayuda nunca pasa del esprint).

### 2.10 Dificultad de la CPU en el partido 3D (20-10, pedido del dueño)
- HECHO: 6 niveles como FC (`MotorJugable.DIFICULTADES`: Principiante, Amateur, Semiprofesional,
  Profesional = el motor de siempre, Clase mundial, Leyenda). Solo afecta al equipo de la CPU frente
  al tuyo (`equipo_cpu()`): calidad de sus jugadores (×0,75 … ×1,12) y presión (−1/+1). Botón
  «🤖 Dificultad de la CPU» en ⚙ del partido (se guarda en ajustes, `dificultad_cpu`).
- Medido (sonda `DIFICULTAD=`, 24-48 partidos, mismo once): contra Principiante el rival gana 44 %
  y la CPU 10 %; contra Leyenda el rival gana 4 % y la CPU 29 % (muchos empates).
- LECCIÓN: «pensar más con el balón» NO hace a la CPU más torpe: conduce más y tira más (jugando
  contra Principiante con pausa ×1,5 la CPU tiró 7 veces). Por eso la dificultad no la usa.
- Jugado por Claude: contra Principiante 2-0 (5 tiros contra 1); contra Leyenda 0-0.
- Pendiente: la Carrera de Jugador no la usa aún (¡cuidado con ese modo!); la dificultad de la
  carrera (fácil/normal/leyenda del inicio) sigue tocando solo el dinero.

### 2.4 Pedidos del dueño en espera
- **Vídeo gameplay** (punto 15 de la MEGA AUDITORÍA 2): pausado por el dueño el 17-10.
- **Reescribir el historial** para bajar el peso del repo (solo binarios viejos, nunca código), después de fusionar a main.
- 🔒 Dueño: FPS en hardware real, builds, keystore, licencias, derechos de imagen, música, voz.

## 3. Cómo se trabaja (resumen de reglas, detalle en `CLAUDE.md`)
- Rama asignada de la sesión (19-10: `ccr-54306f57-jlcywg`); commit y push por bloque; sin identificadores de modelo.
- Banco: `herramientas/banco.sh` → «FIN. 0 fallos» antes de subir. Prueba del acta: `pruebas/prueba_partido_motor.tscn`.
- Lo visual en Forward+ con `herramientas/captura.sh` (JPG) y comprobado con la cámara de TV del partido.
- Contenedor nuevo: Godot 4.7.2 no viene instalado (bajarlo de godot-builds en GitHub); `git lfs pull --include="dinastia-godot/**"` antes de abrir Godot; tras clases nuevas, `godot --headless --import`.
- Agentes: máximo 1-2; revisar su diff antes de unir; borrar el worktree al terminar.
- **Uso**: el 17-10 el límite semanal estaba al 86 % (se restablece el viernes 00:00) → ahorrar hasta entonces.
