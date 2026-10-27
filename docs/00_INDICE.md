# Índice de la documentación (Dinastía)

Regla: **un tema = un documento. Lo pendiente vive en UN solo sitio: [`PLAN_DEL_LUNES.md`](PLAN_DEL_LUNES.md).** Lo completado se borra (el historial de git lo conserva).

| Ruta | Qué contiene |
|---|---|
| `PLAN_DEL_LUNES.md` | Todo lo que falta: dueño, fases 0–6, ruta de lanzamiento, mejoras de código, 356 mejoras, tus ideas sin cerrar |
| `01_metodo/METODO.md` | Cascada + Modelo V, compuertas, trazabilidad |
| `02_vision/ideas_del_dueno/` | Instrucciones y notas originales del dueño (las listas de 300 y 750 ideas pasaron al plan) |
| `04_auditorias/MEGA_AUDITORIA_3.md` | Auditoría del 24-10 con cifras (datos repetibles: `herramientas/auditoria_repo.py`) |
| `04_auditorias/sesion_6.md`, `investigacion_s4/` | Informe de la sesión 6 (recursos libres, «¿por qué?», logros largos, Novedades) e investigación de la s4 |
| `05_referencia/` | Licencias, política de privacidad (para las tiendas), autoloads, índice de capas (generado), lista LFS, textos sin traducir, respaldo en Drive |

Fuera de `docs/`: `CLAUDE.md` (reglas y órdenes vigentes), `material/` (originales de packs), `herramientas/` (scripts), `dinastia-godot/` (el juego).

Borrado el 24-10 (sigue en el historial de git, p. ej. `git log --diff-filter=D -- docs`): diario `LEEME`, `ROADMAP`, `MEGAPLAN` (fases 1-6 y reestructuración), `ESTADO_MEJORAS`, `PENDIENTES`, auditorías e informes anteriores, comparaciones, planes de ruta/etapas/metas, informes extraídos, capturas y vídeos viejos.
**Comentarios del código que citan «ROADMAP», «MEGAPLAN», «LEEME.md» o «PENDIENTES»** (77 en `nucleo/`, `visor/`, `ui/`, medido el 27-10) son
etiquetas de procedencia, no lecturas pendientes: los textos están en `git show 68d32dfc^:dinastia-godot/ROADMAP.md` (igual con
`MEGAPLAN.md`, `LEEME.md`, `PENDIENTES.md`) y en `git show 449c1558^:docs/06_historial/LEEME_diario_2026-09_a_2026-10.md`.
