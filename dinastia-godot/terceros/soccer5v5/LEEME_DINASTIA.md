# soccer5v5-game-godot (respaldo de terceros)

Origen: https://github.com/Habeeb-Rahman-CA/soccer5v5-game-godot (MIT, ver `LICENSE`). Guardado entero por orden del dueño
(01-11-2026): «todo absolutamente todo; lo que quede afuera se queda como respaldo». Lleva `.gdignore`: Godot no lo importa.

- Juego 2D retro (pixel art) de 5 contra 5 en Godot 4.6: máquina de estados de jugadores (pase, entrada, cabezazo, volea,
  chilena, control con el pecho, celebrar…), del balón y del partido; arte, música (4 temas) y efectos (MIT).
- NO USAR sin comprar licencia: la fuente «Daydream» (`assets/fonts/Daydream 1.0 Personal License.txt`: SOLO USO PERSONAL).
  «Pixeled» no trae licencia: no usar hasta confirmarla.
- Ideas de uso: minijuego retro, interfaz, estados del motor.

DATOS REALES (01-11-2026, misma norma que League-Soccer): `assets/json/squads.json` traía 9 clubes REALES (Real Madrid, Barcelona,
PSG, Bayern, Man City, Man United, Liverpool, AC Milan, Inter) con 6 jugadores reales cada uno, y un 10.º club con el autor y sus
amigos. NO se guarda aquí: su DIRECCIÓN es https://github.com/Habeeb-Rahman-CA/soccer5v5-game-godot, `assets/json/squads.json`
(commit en `ORIGEN_COMMIT.txt`). El constante `CLUB` de `scenes/characters/player.gd` y `scenes/game_manager/game_manager.gd`
nombraban esos clubes (son los colores de cada uno en la paleta): aquí ya van con el nombre modificado, como en el minijuego.

INTEGRADO como minijuego en `res://minijuegos/retro5v5/` (rutas reescritas, sin la fuente Daydream, clubes con nombre modificado y
jugadores inventados). El rótulo `worldcup-label.png` («World Cup», marca registrada de la FIFA) NO se copió al minijuego (01-11); sigue solo aquí.
