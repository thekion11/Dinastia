# Aviso de atribución (Apache License 2.0, §4)

Dinastía usa partes de **League-Soccer** (https://github.com/awest813/League-Soccer, commit en `ORIGEN_COMMIT.txt`),
heredero de **Gameplay Football** / Google Research Football.

    Copyright 2019 Google LLC & Bastiaan Konings
    Licensed under the Apache License, Version 2.0 (ver `LICENCIA_Apache-2.0.txt`).

Obras derivadas dentro de Dinastía (todas MODIFICADAS respecto al original: traducidas de C++ a GDScript, con otros ejes,
nombres en español y conectadas a nuestro motor; cada archivo lo indica en su cabecera):

| Archivo de Dinastía | Origen en League-Soccer |
|---|---|
| `visor/league_nucleo.gd` | `src/onthepitch/ballphysics.cpp`, `AIsupport/AIfunctions.cpp`, `player/controller/elizacontroller.cpp`, `player/player.cpp`, `aitactics.hpp`, `gameplaytuning.hpp`, `velocitystate.hpp`, `teamAIcontroller.cpp` |
| `visor/league_reglas.gd` | `src/onthepitch/gameplaytuning.hpp` |
| `visor/league_equipo.gd` | `src/onthepitch/team.cpp`, `teamAIcontroller.cpp`, `AIsupport/AIfunctions.cpp` (AI_GetOffsideLine) |
| `visor/league_sin_balon.gd` | `src/onthepitch/player/controller/strategies/offtheball/default_{def,mid,off}.cpp`, `elizacontroller.cpp`, `playercontroller.cpp`, `teamAIcontroller.cpp`, `player/humanoid/humanoid_utils.cpp` |
| `visor/motor_league.gd`, `visor/motor_league_p1.gd` | integración de lo anterior en `MotorJugable` |
| `datos/league_toques.json`, `visor/league_toques.gd`, `herramientas/league_toques.py` | datos de toque de `data/media/animations/` y el filtro de alcance de `src/onthepitch/player/humanoid/humanoid.cpp` |
| `assets/characters/quaternius/anims_league/league.res` | `data/media/animations/` (293 animaciones convertidas) |
| `audio/ui/` (golpeo y palo) | `data/media/sounds/` |

No se usan sus marcas ni sus datos reales (jugadores, escudos, competiciones). En el juego: Ajustes → Partida → Créditos.
