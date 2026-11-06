# Índice de la documentación (Dinastía)

Regla: **un tema = un documento. Lo pendiente vive en UN solo sitio: [`PLAN_GENERAL.md`](PLAN_GENERAL.md).** Lo completado se borra (el historial de git lo conserva).

| Ruta | Qué contiene |
|---|---|
| `PLAN_GENERAL.md` | Todo lo que falta: dueño, fases 0–6, ruta de lanzamiento, mejoras de código, 356 mejoras, tus ideas sin cerrar |
| `01_metodo/METODO.md` | Cascada + Modelo V, compuertas, trazabilidad |
| `01_metodo/SONAR.md` | Cómo se interpretan los resultados de SonarCloud: qué cuenta como «bien», qué hacer con cada tipo de aviso, `NOSONAR`, CI rojo y cómo repetir el ciclo |
| `02_vision/ideas_del_dueno/` | Instrucciones y notas originales del dueño (las listas de 300 y 750 ideas pasaron al plan) |
| `04_auditorias/MEGA_AUDITORIA_3.md` | Auditoría del 24-10 con cifras (datos repetibles: `herramientas/auditoria_repo.py`) |
| `04_auditorias/HIPER_AUDITORIA_2026-11-02.md` | Hiper auditoría del 2-11: errores H-01…H-11, optimización, visual, jugabilidad y físicas (datos: `datos_auditoria_2026-11-02.json`) |
| `04_auditorias/sesion_6.md`, `investigacion_s4/` | Informe de la sesión 6 (recursos libres, «¿por qué?», logros largos, Novedades) e investigación de la s4 |
| `04_auditorias/rendimiento_120fps.md` | Orden «120 FPS en equipos modestos» (2-11): método de medición (`herramientas/hw_modesto.sh`), cifras antes/después por tanda, descartes medidos, corrección del suelo de 6,9 ms sin pantalla, benchmark y APK |
| `04_auditorias/CIERRE_2026-10-28.md` | Cierre del 27-28-10: qué hizo cada sesión, estado de la rama y avisos para retomar el lunes |
| `05_referencia/` | Licencias, política de privacidad (para las tiendas), autoloads, índice de capas (generado), lista LFS, textos sin traducir, clips del futbolista sin uso (generado), respaldo en Drive |

Fuera de `docs/`: `CLAUDE.md` (reglas y órdenes vigentes), `material/` (originales de packs), `herramientas/` (scripts), `dinastia-godot/` (el juego).

Borrado el 24-10 (sigue en el historial de git, p. ej. `git log --diff-filter=D -- docs`): diario `LEEME`, `ROADMAP`, `MEGAPLAN` (fases 1-6 y reestructuración), `ESTADO_MEJORAS`, `PENDIENTES`, auditorías e informes anteriores, comparaciones, planes de ruta/etapas/metas, informes extraídos, capturas y vídeos viejos.
**Comentarios del código que citan «ROADMAP», «MEGAPLAN», «LEEME.md» o «PENDIENTES»** (77 en `nucleo/`, `visor/`, `ui/`, medido el 27-10) son
etiquetas de procedencia, no lecturas pendientes: los textos están en `git show 68d32dfc^:dinastia-godot/ROADMAP.md` (igual con
`MEGAPLAN.md`, `LEEME.md`, `PENDIENTES.md`) y en `git show 449c1558^:docs/06_historial/LEEME_diario_2026-09_a_2026-10.md`.
