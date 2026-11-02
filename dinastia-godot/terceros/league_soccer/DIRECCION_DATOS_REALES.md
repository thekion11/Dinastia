# Datos reales de League-Soccer: SOLO LA DIRECCIÓN (no copiados)

Orden del dueño (01-11-2026): guardar como referencia los jugadores, escudos, uniformes y competiciones reales que trae
League-Soccer, para RECREARLOS DESPUÉS DE FORMA LEGAL en Dinastía (nombres un poco cambiados pero reconocibles, escudos
parecidos, uniformes base iguales; ver orden 15 de `CLAUDE.md`), cumpliendo la norma: los datos reales solo van en
`pack_real.json` / `caras_reales.pck`, nunca en el repositorio ni en los builds públicos. Por eso aquí NO hay copia de nada:
solo DÓNDE está y QUÉ contiene.

Repositorio: https://github.com/awest813/League-Soccer — commit `087414cde936c3e26ed0b8c244d9d85425ec5657` (Apache 2.0 el
código; los nombres, escudos y uniformes reales son marcas y derechos de terceros, no los cubre esa licencia).

| Qué | Dirección dentro del repositorio | Contenido |
|---|---|---|
| Base de datos | `data/databases/default/database.sqlite` | tablas `regions`, `countries`, `leagues`, `teams`, `players`, `tournaments` |
| Jugadores | tabla `players` (144) | nombre, apellido, posiciones, edad, valoración, 22 atributos físicos/técnicos/mentales (0-1), altura, peso, pelo, piel, club |
| Clubes | tabla `teams` (8) | Ajax, Arsenal, FC Barcelona, Bayern Munich, Borussia Dortmund, Manchester United, PSV Eindhoven, Real Madrid: nombre corto, colores 1 y 2, formación (posición y rol de los 11) y táctica (profundidad, anchura, foco, presión, regate) |
| Competiciones | tabla `leagues` (4) | Premier League, Bundesliga, Eredivisie, La Liga |
| Escudos de clubes | `data/databases/default/images_teams/<liga>/<club>_logo.png` | carpetas `premierleague`, `1bundesliga`, `eredivisie`, `primeradivision` |
| Uniformes | `data/databases/default/images_teams/<liga>/<club>_kit_01.png`, `_kit_02.png` | camiseta de local y de visita por club |
| Logos de competiciones | `data/databases/default/images_competitions/*.png` | `premierleague`, `1bundesliga`, `eredivisie`, `primeradivision` |
| Plantilla de uniforme | `data/databases/default/template_kit.png` | la plantilla UV del uniforme (genérica) |

Para usarlo: los atributos y las tácticas sirven de referencia para la base «ficticia» (mismas estadísticas, nombre
modificado); los escudos y uniformes, como modelo visual para dibujar los nuestros parecidos; nunca se copian tal cual.
