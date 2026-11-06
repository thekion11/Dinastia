# Propuesta (NO activada): `paths-ignore` en el disparador `push` de `compilar.yml` (6-11-2026)

**Problema.** Cada push, aunque solo cambie un `.md`, lanza ~25 trabajos (banco, 6 especiales, iconos, 5 exportaciones y sus verificaciones…).
Con 4 sesiones empujando a la vez la cola de ejecutores se atasca (ejecuciones en espera >30 min).

**Cambio (parche listo, sin aplicar):** `docs/04_auditorias/propuestas/paths_ignore_compilar.patch` → `git apply` y commit.
```yaml
on:
  push:
    branches: [ "**" ]
    paths-ignore: [ "docs/**", "**/*.md", "!docs/05_referencia/LICENCIAS.md" ]
```

**Qué dejaría de correr en un push que SOLO toca `docs/**` o `*.md`:** banco, especiales (incluida la norma de 450 líneas y la sincronía
LISTA.txt↔especiales.sh), exportaciones y sus verificaciones, el borrador de Release. `plataformas.yml` ya filtra por rutas (`dinastia-godot/**`) y no corre.
**Qué sigue corriendo:** SonarCloud (análisis automático del PR y de `main`), los eventos `pull_request` si los hubiera, y todo `workflow_dispatch`.

**Riesgos y mitigaciones.**
1. Un documento que alguna prueba LEE: hallado con `grep -rIn "docs/" dinastia-godot/pruebas` → **uno**: `pruebas/ideas/f0m_nucleo.gd` lee
   `docs/05_referencia/LICENCIAS.md` (comprueba que cada autor citado está en la lista). Por eso el parche lo EXCLUYE del filtro (`!docs/05_referencia/LICENCIAS.md`).
   Si se añade otra prueba que lea documentación, hay que añadir su ruta con `!`. (Las herramientas de `herramientas/*.py` que leen `docs/` no son pruebas del CI.)
2. `paths-ignore` se evalúa por push entero: un push con docs + código SÍ lanza todo (correcto).
3. Un cambio de `.md` dentro de `dinastia-godot/` que se empaqueta en el export (el preset Web excluye `*.md`; los demás presets no los he revisado): confirmar que ninguno empaqueta un `.md` que cambie el juego.
4. La rama debe tener su último push COMPLETO verde antes de unir; si el último push fue solo docs, el estado verde es el del push anterior (el PR muestra el último con CI). Para forzar CI completo: `workflow_dispatch`.
5. Con `paths-ignore`, GitHub no crea checks para ese push: si hubiera protección de rama con checks obligatorios, un PR de solo docs quedaría esperando
   (no he podido comprobar desde aquí si hay protección de rama con checks obligatorios: confirmarlo en Settings → Branches antes de activar).

**Activación (decide el dueño):** aplicar el parche en una rama, comprobar que un push de solo docs NO crea ejecuciones y que uno de código SÍ.
Ahorro real medido: de los últimos 60 commits de `main`, 5 tocan SOLO documentación (≈8 %). En ramas de trabajo con muchos commits de registro puede ser más; el beneficio
principal es evitar la cola en los momentos de mucho empuje, no el total de minutos.
