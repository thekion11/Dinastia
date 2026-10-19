# PENDIENTES — qué falta, cómo se hará y qué falta fusionar

Documento de traspaso: si la sesión se corta o el contenedor se pierde, desde aquí se retoma.
Última actualización: **19-10-2026**. Se actualiza en cada bloque de trabajo.

## 1. Qué falta por FUSIONAR

| Qué | Dónde está | Estado | Cómo se fusiona |
|---|---|---|---|
| Todo lo hecho del 14 al 17-10 | `main` | **FUSIONADO el 17-10 con el PR #7** | nada pendiente; lo nuevo que se haga va en la rama y se pasa con otro PR cuando el dueño lo pida |
| Tanda 2 del TOP 25, mejoras del coche/GPS y caza de bugs del 17-10 | `main` | **fusionado el 17-10 con el PR #8** (pedido del dueño) | nada pendiente |
| Línea defensiva (M-123), notas de partidos mirados, prueba del bono, física M-114/115 (19-10) | rama `ccr-54306f57-jlcywg` | sin fusionar | PR nuevo cuando el dueño lo pida |

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
- ~~**Notas de los partidos mirados**~~ HECHO 19-10: `Partido.cerrar_notas_mirado()` (desde `Mundo.avanzar_semana`), una vez, con la nota de `valoraciones()` y sin tocar el `Azar`.
- **Cambio con cartel y palmada**: solo en el partido del DT, falta en la Carrera de Jugador.
- ~~**Prueba frágil** `_probar_motor_libre` («bono del club»)~~ 19-10: con +20 % el efecto quedaba bajo el ruido de 12 partidos; ahora prueba la dirección con +35 %.
- **Optimización** (19-10, cifras CORREGIDAS): `medir_partido` medía la CEREMONIA (alineaciones), no el juego; ya la salta. En juego real con la cámara de TV (ALTO, Forward+): **532 llamadas y 1,34 M triángulos** (no 0,76 M). HECHO: ojos solo hasta 35 m (`VestidorQ.DIST_OJOS`) → 493 llamadas (−7 %), sin diferencia visible en la toma de TV (de cerca sí harían falta: la cuenca queda clara). Probado y descartado: butacas cercanas livianas (`LIVIANAS=1`): no bajan los triángulos (desde la TV casi no se ven). Pendiente: averiguar qué pone los 1,34 M en pantalla (cuerpos SuperHero ~12,5 mil por jugador, público) y si `CaraReal` puede tener un corte de lejos sin dejar la cara hundida.
- **Red del arco**: onda más ancha y lenta (17-10), techo sin asomar por el larguero. **Cartel del cuarto árbitro**: sigue notándose poco desde la TV.

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
