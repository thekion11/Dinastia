# PENDIENTES — qué falta, cómo se hará y qué falta fusionar

Documento de traspaso: si la sesión se corta o el contenedor se pierde, desde aquí se retoma.
Última actualización: **17-10-2026**. Se actualiza en cada bloque de trabajo.

## 1. Qué falta por FUSIONAR

| Qué | Dónde está | Estado | Cómo se fusiona |
|---|---|---|---|
| Todo lo hecho del 14 al 17-10 | `main` | **FUSIONADO el 17-10 con el PR #7** | nada pendiente; lo nuevo que se haga va en la rama y se pasa con otro PR cuando el dueño lo pida |
| Tanda 2 del TOP 25 (M-104, M-160, M-141, M-051, M-238 y operadores del VAR) | **unida a `claude/godot-project-review-o1dvr1` el 17-10** (subida) | banco 0 fallos | ya no queda nada fuera de la rama: solo falta el PR a `main` |

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
| M-123 | Línea defensiva común y trampa del fuera de juego | en `MotorJugable`: la línea de 4 se mueve junta según `tactica.linea`/`fuera_de_juego`; medir con `sonda_motor_dt` (fueras de juego por partido) |
| M-114/115 | Reposiciones del balón y giros bruscos | `pruebas/sonda_fisica_partido.tscn` ya los mide; separar teletransportes de saques y limitar giro °/s |
| M-263 | Semana con agenda en la Carrera de Jugador | calendario entreno/descanso/vida social entre partidos en `carrera_jugador.gd` |
| M-040 | Gente del club y de la ciudad en primeras filas | reutilizar `PeatonQ` horneados en las 2 primeras filas (`StadiumBuilder._montar_horneados`) |
| M-033 | Variedad de ropa y pelo en hinchas | más variantes horneadas (`herramientas/hornear_publico.gd`) |
| M-036/044 | Grada que reacciona en onda y la ola | uniformes de tiempo/origen en `hinchada.gdshader` |
| M-132 | Repetición manual de los últimos 10 s | `Repeticion` ya graba; botón en la pausa |
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
- **Notas de los partidos mirados** (en vivo/3D) no se cierran en `Jugador.notas` (solo en `simular()`); arreglarlo cambia el azar (anotado en M-141).
- **Cambio con cartel y palmada**: solo en el partido del DT, falta en la Carrera de Jugador.
- **Prueba frágil** `_probar_motor_libre` («bono del club»): pasa o falla según qué secciones corren antes en su proceso; la de prórroga va con coste 0.01 para no moverla. Arreglo real: que esa sección cree jugadores frescos y mida con más partidos.
- **Optimización**: los triángulos bajaron −66 % pero las llamadas de dibujo solo −11 % → juntar ojos/cejas/cuero en la cara a distancia.
- **Red del arco**: onda más ancha y lenta (17-10), techo sin asomar por el larguero. **Cartel del cuarto árbitro**: sigue notándose poco desde la TV.

### 2.5 Caza de bugs del 17-10 (estrés pedido por el dueño) — se registra todo al encontrarlo
- ~~Partido dirigido: cerrar el juego perdiendo permitía repetirlo hasta ganar~~ HECHO (`PartidoPendiente`).
- ~~Atravesar paredes con un coche encima o con un tirón de fotogramas~~ HECHO (`_mover_un_trozo`).
- Atropellar peatones: el coche rebota (son obstáculos móviles). No hay daño ni reacción del peatón: sin arreglar (diseño).
- Coches del tráfico y autobús: E no hace nada (no se pueden robar ni subir al bus). Inofensivo; posible mejora.
- Metro: E en marcha = «bajar en la próxima»; no se puede salir en el túnel. Correcto.
- Esc bajo tierra (metro/galería): el entorno se restaura en `_exit_tree`. Correcto.
- **MENÚS A VELOCIDAD SOBREHUMANA** (`pruebas/estres_menus.tscn`, 400 fotogramas, 2-6 acciones por fotograma):
  · El contenedor de pestañas `_pestanas` acaba LIBERADO (se «muda» a una PantallaMenu y se borra con ella):
    luego `get_tab_count` sobre instancia liberada (1001 veces), y el juego queda sin pantallas (1282 → 497 nodos).
  · `_perezoso` (Principal), `pintar` y `PantallaMenu._mudar` reciben nodos ya liberados.
  · `BotonFx`: 177 000 avisos «signal already connected» (`_sonar`, `_a`, `_arriba`): se conecta dos veces el mismo botón.

### 2.4 Pedidos del dueño en espera
- **Vídeo gameplay** (punto 15 de la MEGA AUDITORÍA 2): pausado por el dueño el 17-10.
- **Reescribir el historial** para bajar el peso del repo (solo binarios viejos, nunca código), después de fusionar a main.
- 🔒 Dueño: FPS en hardware real, builds, keystore, licencias, derechos de imagen, música, voz.

## 3. Cómo se trabaja (resumen de reglas, detalle en `CLAUDE.md`)
- Rama `claude/godot-project-review-o1dvr1`; commit y push por bloque; sin identificadores de modelo.
- Banco: `herramientas/banco.sh` → «FIN. 0 fallos» antes de subir. Prueba del acta: `pruebas/prueba_partido_motor.tscn`.
- Lo visual en Forward+ con `herramientas/captura.sh` (JPG) y comprobado con la cámara de TV del partido.
- Contenedor nuevo: `git lfs pull --include="dinastia-godot/**"` antes de abrir Godot; tras clases nuevas, `godot --headless --import`.
- Agentes: máximo 1-2; revisar su diff antes de unir; borrar el worktree al terminar.
- **Uso**: el 17-10 el límite semanal estaba al 86 % (se restablece el viernes 00:00) → ahorrar hasta entonces.
