# MEGA AUDITORÍA 4 (4-11-2026, orden 31 del dueño)

Profunda, de TODO el juego, con 5 repasos. Después: caza y arreglo de fallos sin parar hasta nueva orden.

## Reparto por área (un archivo por área en esta carpeta)
| Área | Sesión | Archivo |
|---|---|---|
| Partido: motor jugable, partido simulado, físicas, IA, táctil, penales, árbitro | PES 6 | `partido.md` |
| Interfaz: menús, pantallas, idiomas, accesibilidad, tutorial, arranque y modos, guardado/carga, actualizador | Ejecutora | `interfaz.md` |
| Mundo 3D: ciudad, estadio, transporte, personajes, peatones, calidad gráfica y rendimiento visual | Ciudad | `mundo_3d.md` |
| Reglas del proyecto y salud del código: CLAUDE.md (450 líneas, LFS, datos reales, modelos, traducciones, memoria del menú, C++ = GDScript), pruebas, CI, documentos | Búsqueda de fallos | `reglas_y_codigo.md` |
| Gestión: economía, mercado, contratos, cantera, competiciones, carrera, federación, rendimiento y memoria | Líder | `gestion.md` |

## Los 5 repasos
1. **Lectura**: recorrer el código del área archivo por archivo; anotar lo sospechoso.
2. **Ejecución**: correr bancos, especiales y bancos especializados del área (`herramientas/bancos_especiales.py <banco>`) y jugar el área (escenas de prueba, capturas con la cámara real).
3. **Al límite**: estrés y casos absurdos (partidas de 20+ temporadas, guardar/cargar en mitad de todo, sin dinero, plantel vacío, 160 % de texto, sin red, pulsaciones dobles, cambiar idioma/calidad a mitad, valores extremos).
4. **Reglas y coherencia**: lo que no se repite igual (determinismo), reglas de CLAUDE.md, textos sin traducir, rutas `res://` rotas, señales sin desconectar, fugas de memoria/nodos.
5. **Cruzado**: cada sesión repasa el área de OTRA (rota: partido→interfaz→mundo_3d→reglas→gestión→partido) buscando lo que se escapó.

## Formato de cada hallazgo
`- [A4-<AREA>-NNN] (repaso N, gravedad: crítico|alto|medio|bajo) Qué falla. Cómo reproducirlo. Archivo:línea. Estado: abierto|arreglado (commit)|pregunta al dueño.`
- Se arreglan SOLO bugs claros (con prueba que lo cubra). Lo que cambie cómo se juega → «pregunta al dueño» y se sigue con otro.
- Arreglos: rama propia de cada sesión → PR contra `claude/dazzling-rubin-v7rfyi` (el líder une y pasa a `main`). Banco 0 y líneas 0 antes de subir.
