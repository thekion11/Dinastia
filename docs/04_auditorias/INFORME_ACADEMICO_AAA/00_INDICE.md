# Dinastía hacia el nivel AAA — Informe académico (inicio: 16-11-2026)

Encargo del dueño (16-11): informe de nivel académico que analice todo el juego, encuentre fallos e investigue con fuentes qué hace falta para llegar al nivel AAA y superar a eFootball PES 2020 y EA Sports FC 27.
Alcance acordado: 40.000-80.000 palabras, por capítulos, guardados y subidos uno a uno. El resumen ejecutivo previo está en `../INFORME_AAA_2026-11-16.md` (hoja de ruta y 100 tareas).

## Capítulos

| # | Capítulo | Archivo | Estado |
|---|---|---|---|
| 1 | Introducción, preguntas de investigación y método | `cap_01_introduccion_metodo.md` | hecho (16-11) |
| 2 | Estado del arte (PES 2020, FC 24-27, game feel, animación, analítica, producción) | `cap_02_estado_del_arte.md` | hecho (16-11) |
| 3 | Arquitectura de Dinastía (cifras del código) | `cap_03_arquitectura.md` | hecho (16-11) |
| 4 | Rendimiento medido | `cap_04_rendimiento.md` | hecho (16-11) |
| 5 | Pruebas automáticas reales (banco y especiales) | `cap_05_pruebas_automaticas.md` | hecho (16-11) |
| 6 | Fallos del motor del partido (auditoría estática) | `cap_06_fallos_motor_partido.md` | hecho (16-11) |
| 7 | Fallos de gestión, La Ruta y menús | `cap_07_fallos_gestion_ruta_menus.md` | hecho (16-11) |
| 8 | Brechas frente a PES 2020 y FC 27 (síntesis con fuentes) | `cap_08_brechas.md` | hecho (16-11) |
| 9 | Plan hacia 1.0: hitos, métricas y criterios de aceptación | `cap_09_plan.md` | hecho (16-11) |
| 10 | Conclusiones y bibliografía unificada | `cap_10_conclusiones.md` | hecho (16-11) |
| 11 | Recursos públicos gratuitos con licencia comercial (catálogo por necesidad, top 25, plantilla para `LICENCIAS.md`) | `cap_11_recursos_publicos.md` | hecho (16-11) |

## Convenciones
- [M] medido · [D] documento del proyecto · [F n] fuente externa numerada (bibliografía del cap. 2) · [E] estimación.
- Cada fallo lleva archivo:línea, escenario reproducible, arreglo propuesto y veredicto (CONFIRMADO / PLAUSIBLE). Este informe NO corrige código: los arreglos se hacen después, con el banco en «FIN. 0 fallos».

## Recuento de palabras (`wc -w cap_*.md`, 16-11)

| Cap. | Palabras |
|---|---|
| 1 | 3.911 |
| 2 | 12.145 |
| 3 | 5.619 |
| 4 | 5.031 |
| 5 | 4.894 |
| 6 | 10.585 |
| 7 | 10.030 |
| 8 | 5.641 |
| 9 | 4.476 |
| 10 | 5.266 (de ellas ~2.670 de bibliografía unificada) |
| 11 | 12.667 |
| **Total** | **80.265** |

Capítulos 1, 3, 4, 8, 9 y 10 (redactados el 16-11 en la segunda tanda): 29.944 palabras. La bibliografía unificada (cap. 10, §10.7) conserva [F 1]-[F 68] del capítulo 2 y numera las del capítulo 11 como [F 69]-[F 137] = [R 1]-[R 69].
