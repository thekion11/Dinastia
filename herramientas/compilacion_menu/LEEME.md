# Análisis de la compilación del menú (3-11-2026)
Herramientas de `docs/04_auditorias/compilacion_menu_2026-11-03.md`. Python 3 + Godot en `/tmp/bin/godot`; no tocan el juego.
- `grafo.py`: grafo de dependencias entre scripts (cada `class_name`, autocarga, `extends "res://…"` o `preload` nombrado en un script es una arista) y alcance desde `ui/principal.gd` + autocargas.
- `dom.py`: árbol de dominadores de ese grafo (qué scripts SOLO entran por un puente) y su peso en bytes de fuente.
- `puentes.py`, `fam.py`: lista de puentes y reparto por familias (ciudad, estadio/partido, pantallas, otros; escribe `fam.json`).
- `exper.py <nombre> <familias>`: copia el proyecto en `/tmp/exp_<nombre>`, convierte a `load("res://…")` las referencias a la familia desde fuera de ella (EXPERIMENTAL: el código resultante solo sirve para medir),
  exporta el `.pck` precompilado y mide la RAM con `mem3.gd.txt` (copiar a `/tmp/mem3.gd`). `ninguna` = control (también quita la inferencia `:=` en todo el proyecto, para que las comparaciones sean justas).
