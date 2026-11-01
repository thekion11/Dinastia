# League-Soccer (respaldo de terceros)

Origen: https://github.com/awest813/League-Soccer (Apache 2.0; ver `LICENCIA_Apache-2.0.txt` y `ORIGEN_COMMIT.txt`).
Heredero de GameplayFootball / Google Research Football. Guardado por orden del dueño (01-11-2026): «todo absolutamente
todo, lo que quede afuera se queda como respaldo».

- `animaciones/`: las 296 animaciones de fútbol originales (formato `.anim` de texto: por articulación, cuadros de 10 ms y
  cuaterniones x,y,z,w; Z arriba, el jugador mira a −Y, su izquierda es +X; la rotación SUSTITUYE a la de reposo, que es
  la extremidad recta y colgando). Las convierte a nuestro esqueleto `herramientas/league_anim_a_res.gd`.
- `player.object`: la jerarquía y las posiciones de las articulaciones de origen.

Lo que NO va a los builds públicos: su base de datos trae jugadores y escudos REALES (solo en el paquete real).

- `codigo_y_recursos/`: el resto del repositorio (código C++, modelos 3D .ase, texturas, sonidos, menús, shaders, idiomas,
  documentación, pruebas y herramientas). FUERA a propósito (reglas del proyecto: datos reales solo en el paquete real): la base de
  datos `database.sqlite` (jugadores REALES), `images_teams` y `images_competitions` (escudos y logos REALES). Siguen en el origen.

Uso en el juego (01-11-2026): `assets/characters/quaternius/anims_league/league.res` (las 293 + espejos, nombres `ls_…`);
la carrera rápida («correr») es ya el paso de sprint de League-Soccer (`visor/league_anim.gd`).
