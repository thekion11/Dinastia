# PENDIENTES — qué falta, cómo se hará y qué falta fusionar

Documento de traspaso: si la sesión se corta o el contenedor se pierde, desde aquí se retoma.
Última actualización: **17-10-2026**. Se actualiza en cada bloque de trabajo.

## 1. Qué falta por FUSIONAR

| Qué | Dónde está | Estado | Cómo se fusiona |
|---|---|---|---|
| Todo lo hecho desde el 14-10 (≈140 commits: VAR que anula, duelos, faltas, optimización −58 %, camiseta 3D, prórroga y penales, informe del rival, moral del Camarín, árbitros, GPS, etc.) | rama `claude/godot-project-review-o1dvr1` (en GitHub) | subido, banco en 0 fallos | **a `main` con un PR nuevo** cuando el dueño lo pida (el último fusionado fue el PR #6, 14-10) |
| Tanda 2 del TOP 25: cambio de jugador con cartel y palmada (M-104), sorteo con moneda (M-160), notas por jugador y mejor del partido (M-141), escudo más grande con relieve (M-051), operadores del VAR con ropa normal, escena de despido del DT (M-238, a medias) | worktree local del agente (`worktree-agent-a703e0231e5d8e3ed`, **solo en este contenedor**) | 6 commits + cambios sin confirmar; el agente seguía trabajando | **Respaldo en el repo**: `parches_pendientes/tanda2_top25_commits.patch` (los 6 commits) y `parches_pendientes/tanda2_top25_sin_confirmar.patch` (lo de después, sin imágenes). Si se pierde el contenedor: `git am parches_pendientes/tanda2_top25_commits.patch` y luego `git apply parches_pendientes/tanda2_top25_sin_confirmar.patch`, `godot --headless --import`, banco en 0 fallos y terminar el despido (M-238). Si el agente termina antes: unir su rama con merge y borrar estos parches |

## 2. Qué falta HACER (por orden) y CÓMO

Fuente completa: `ESTADO_MEJORAS.md` (470 puntos con su estado + TOP 25) y `COMPARACION_JUEGOS_2.md`.

### 2.1 Del TOP 25 que queda
| Id | Qué | Cómo |
|---|---|---|
| M-238 | Despido del DT (si el respaldo no lo trae terminado) | pantalla con el presidente (cara 3D `Tutorial._cara_mentor`), `CuadroDialogo`, resumen de la etapa, opciones existentes para seguir |
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
- **Penales**: entran ~9 de 10 y el tiro del usuario sin apuntar va al centro y marca si el portero se tira → calibrar con más partidos (`pruebas/prueba_prorroga_penales.tscn`).
- **Añadido**: no suma el tiempo de lesiones (M-139 PARCIAL).
- **Once automático de la IA**: a veces pone delanteros de lateral (se ve en rojo en el informe del rival) → revisar `Club.once()` (peso de `encaja`).
- **Prueba frágil** `_probar_motor_libre` («bono del club»): pasa o falla según qué secciones corren antes en su proceso; la de prórroga va con coste 0.01 para no moverla. Arreglo real: que esa sección cree jugadores frescos y mida con más partidos.
- **Optimización**: los triángulos bajaron −66 % pero las llamadas de dibujo solo −11 % → juntar ojos/cejas/cuero en la cara a distancia.
- **Red del arco y cartel del cuarto árbitro**: se notan poco desde la cámara de TV.

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
