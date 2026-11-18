# Análisis estático de TODO el GDScript — 2026-11-18

- Alcance: **2541 archivos `.gd`** rastreados por git (incluye `terceros/`), **357,054 líneas** físicas.
- Motivo: SonarCloud no tiene analizador de GDScript (solo ve ~23.000 líneas de Python/C++/etc.). Se analiza el GDScript con tres métodos independientes, **cada uno ejecutado 3 veces**.
- Herramienta: `dinastia-godot/herramientas/analizar_gd.py <lint|forma|ast> salida.jsonl` (gdtoolkit 4.5.0). No se modificó ningún `.gd`.

## Verificación de repetibilidad (3 pasadas por método)

| Método | Qué hace | Hallazgos | Pasada 1 = 2 = 3 (huella MD5) |
|---|---|---:|---|
| lint | `gdlint`: reglas de estilo, orden de clases, nombres, retornos, argumentos sin uso… | 33,483 | idénticas (`e6a19686b85f`) |
| forma | `gdparse` (sintaxis) + `gdformat --diff` (bloques que cambiarían de formato) | 16,700 | idénticas (`cfd4070be9ad`) |
| ast | Analizador propio sobre el árbol sintáctico: tamaño, complejidad, anidamiento, parámetros, duplicados, depuración, igualdad de flotantes… | 4,010 | idénticas (`002f9aff5644`) |

Las 9 pasadas dieron resultados byte a byte iguales (tras normalizar un mensaje de error no determinista de gdparse en la primera ronda; esa ronda se descartó y se repitió completa).

**Total: 54,193 hallazgos** (215 en `terceros/`, que Sonar excluye).

## Método `lint` por regla

| Regla | Cantidad |
|---|---:|
| `gdlint:max-line-length` | 30,042 |
| `gdlint:class-definitions-order` | 2,644 |
| `gdlint:class-variable-name` | 165 |
| `gdlint:duplicated-load` | 128 |
| `gdlint:trailing-whitespace` | 118 |
| `gdlint:function-variable-name` | 107 |
| `gdlint:unused-argument` | 83 |
| `gdlint:function-argument-name` | 59 |
| `gdlint:max-returns` | 52 |
| `gdlint:comparison-with-itself` | 19 |
| `gdlint:max-public-methods` | 18 |
| `gdlint:expression-not-assigned` | 11 |
| `gdlint:load-constant-name` | 7 |
| `gdlint:fallo-analisis` | 6 |
| `gdlint:no-elif-return` | 5 |
| `gdlint:loop-variable-name` | 5 |
| `gdlint:function-arguments-number` | 4 |
| `gdlint:no-else-return` | 3 |
| `gdlint:unnecessary-pass` | 3 |
| `gdlint:function-name` | 3 |
| `gdlint:mixed-tabs-and-spaces` | 1 |

## Método `forma` por regla

| Regla | Cantidad |
|---|---:|
| `gdformat:formato` | 16,693 |
| `gdparse:sintaxis` | 6 |
| `forma:sin-salto-final` | 1 |

## Método `ast` por regla

| Regla | Cantidad |
|---|---:|
| `ast:depuracion` | 2,311 |
| `ast:complejidad-ciclomatica` | 553 |
| `ast:funcion-larga` | 437 |
| `ast:igualdad-flotante` | 233 |
| `ast:muchos-parametros` | 220 |
| `ast:anidamiento` | 149 |
| `ast:variable-sin-uso` | 61 |
| `ast:archivo-largo` | 31 |
| `ast:pendiente` | 6 |
| `ast:no-parsea` | 6 |
| `ast:await-doble` | 3 |

## Archivos que NO se pudieron analizar (errores de sintaxis para gdtoolkit)

Pueden ser sintaxis de Godot 4.7 que gdtoolkit 4.5 aún no soporta, o errores reales: **hay que verificarlos con Godot** (`godot --headless --import`).

- `dinastia-godot/pruebas/inventario_partido_gpu.gd` — Unexpected token Token('RSQB', ']') at line 64, column 113.
- `dinastia-godot/pruebas/so/com_guardado_ida_vuelta.gd` — Unexpected token Token('TYPE_HINT', 'rutas_con_mayusculas') at line 43, column 26.
- `dinastia-godot/ui/componentes/escaparate_barra.gd` — Unexpected token Token('RPAR', ')') at line 94, column 93.
- `dinastia-godot/ui/componentes/pantalla_menu.gd` — Unexpected token Token('RPAR', ')') at line 175, column 79.
- `dinastia-godot/ui/estadio_p4.gd` — Unexpected token Token('RSQB', ']') at line 397, column 77.
- `dinastia-godot/visor/control_partido.gd` — No terminal matches '﻿' in the current parser context, at line 1 col 1

## Top 25 archivos con más hallazgos

| Archivo | Hallazgos |
|---|---:|
| `dinastia-godot/nucleo/idiomas_p1.gd` | 223 |
| `dinastia-godot/nucleo/leyes_pais.gd` | 183 |
| `dinastia-godot/pruebas/banco/funciones.gd` | 167 |
| `dinastia-godot/visor/anim_futbol_p2.gd` | 159 |
| `dinastia-godot/ui/principal_p1.gd` | 152 |
| `dinastia-godot/visor/mejoras_c4_p1.gd` | 149 |
| `dinastia-godot/pruebas/banco/varios_p11_p1.gd` | 142 |
| `dinastia-godot/visor/motor_league.gd` | 140 |
| `dinastia-godot/visor/motor_jugable_p1.gd` | 133 |
| `dinastia-godot/pruebas/banco/varios_p11.gd` | 131 |
| `dinastia-godot/visor/mejoras_c4_avance.gd` | 131 |
| `dinastia-godot/pruebas/banco/varios_p13.gd` | 130 |
| `dinastia-godot/pruebas/banco/varios_p12.gd` | 129 |
| `dinastia-godot/pruebas/banco/partido_p3.gd` | 128 |
| `dinastia-godot/pruebas/banco/partido.gd` | 122 |
| `dinastia-godot/pruebas/banco/ciudad.gd` | 121 |
| `dinastia-godot/ui/cara_p1.gd` | 118 |
| `dinastia-godot/visor/motor_combinado.gd` | 116 |
| `dinastia-godot/pruebas/banco/partido_p4.gd` | 114 |
| `dinastia-godot/pruebas/banco/paises_csv.gd` | 111 |
| `dinastia-godot/visor/edificio_club_p1.gd` | 111 |
| `dinastia-godot/pruebas/banco/ruta.gd` | 110 |
| `dinastia-godot/pruebas/banco/varios_p10.gd` | 109 |
| `dinastia-godot/pruebas/probar_nativo.gd` | 108 |
| `dinastia-godot/visor/league_locomocion.gd` | 107 |

## Por carpeta de primer nivel

| Carpeta | Hallazgos |
|---|---:|
| `dinastia-godot/pruebas` | 21,868 |
| `dinastia-godot/visor` | 12,050 |
| `dinastia-godot/ui` | 11,814 |
| `dinastia-godot/nucleo` | 7,580 |
| `dinastia-godot/herramientas` | 350 |
| `dinastia-godot/minijuegos` | 225 |
| `dinastia-godot/terceros` | 215 |
| `dinastia-godot/addons` | 91 |

## Lectura

- 30,042 de 33,483 avisos de `gdlint` son líneas de más de 100 caracteres (límite por defecto de gdlint; el proyecto no define otro). Es ruido de estilo, no de fallos.
- Lo que más importa: 553 funciones con complejidad ciclomática > 15, 437 funciones de más de 80 líneas, 31 archivos > 450 líneas (**incumplen la norma del proyecto**), 233 comparaciones `==`/`!=` con flotantes (misma regla que Sonar S1244 en otros lenguajes) y 61 variables locales sin uso.
- `ast:depuracion` (2,311) son llamadas `print(...)` al inicio de línea; en pruebas y herramientas son normales, en código del juego conviene revisarlas.
- Los métodos son heurísticos: pueden dar falsos positivos (p. ej. variables 'sin uso' que se usan solo en una cadena, o duplicados legítimos). Nada se ha corregido ni cambiado.
- Datos completos, una línea JSON por hallazgo (`archivo`, `linea`, `regla`, `mensaje`, `sev`): `lint.jsonl`, `forma.jsonl`, `ast.jsonl` en esta misma carpeta.
