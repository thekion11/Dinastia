# Propuesta (NO activada): `paths-ignore` en el disparador `push` de `compilar.yml` (6-11-2026)

**Problema.** Cada push, aunque solo cambie un `.md`, lanza ~25 trabajos (banco, 6 especiales, iconos, 5 exportaciones y sus verificaciones…).
Con 4 sesiones empujando a la vez la cola de ejecutores se atasca (ejecuciones en espera >30 min).

**Cambio (parche listo, sin aplicar):** `docs/04_auditorias/propuestas/paths_ignore_compilar.patch` → `git apply` y commit.
```yaml
on:
  push:
    branches: [ "**" ]
    paths-ignore: [ "docs/**", "**/*.md" ]
```

**Qué dejaría de correr en un push que SOLO toca `docs/**` o `*.md`:** banco, especiales (incluida la norma de 450 líneas y la sincronía
LISTA.txt↔especiales.sh), exportaciones y sus verificaciones, el borrador de Release. `plataformas.yml` ya filtra por rutas (`dinastia-godot/**`) y no corre.
**Qué sigue corriendo:** SonarCloud (análisis automático del PR y de `main`), los eventos `pull_request` si los hubiera, y todo `workflow_dispatch`.

**Riesgos y mitigaciones.**
1. Un `.md` que alguna prueba LEE (p. ej. `CLAUDE.md`, `docs/PLAN_GENERAL.md`, `docs/00_INDICE.md`) y cuyo cambio rompería algo → hoy no hay pruebas que lo lean
   (comprobado: `grep -rn "\\.md" dinastia-godot/pruebas | grep -i "load\\|open"` sin lecturas de documentación; las pruebas de textos usan `datos/*.json`). Si aparece alguna, excluir su ruta del filtro.
2. `paths-ignore` se evalúa por push entero: un push con docs + código SÍ lanza todo (correcto).
3. Un cambio de `.md` dentro de `dinastia-godot/` que se empaqueta en el export (los presets excluyen `*.md`): no afecta a los builds.
4. La rama debe tener su último push COMPLETO verde antes de unir; si el último push fue solo docs, el estado verde es el del push anterior (el PR muestra el último con CI). Para forzar CI completo: `workflow_dispatch`.
5. Con `paths-ignore`, GitHub no crea checks para ese push: si hubiera protección de rama con checks obligatorios, un PR de solo docs quedaría esperando
   (el repo no tiene checks obligatorios hoy; confirmar en Settings → Branches antes de activar).

**Activación (decide el dueño):** aplicar el parche en una rama, comprobar que un push de solo docs NO crea ejecuciones y que uno de código SÍ.
Ahorro estimado: los pushes de solo documentación son ~1 de cada 4 de las sesiones de hoy (registros, planes, auditorías).
