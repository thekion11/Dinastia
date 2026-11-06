# Propuesta (NO activada): SonarCloud desde el CI en vez del análisis automático (6-11-2026)

**Hoy:** SonarCloud usa *análisis automático*: solo analiza `main` y los PR; una rama sin PR no se analiza y el CI nunca falla por la puerta de calidad
(el comentario del bot aparece en el PR, pero ningún `required check` del CI lo lee).

**Cambio propuesto:** un trabajo `sonar` (borrador en `docs/04_auditorias/propuestas/sonar_ci.yml.desactivado`, FUERA de `.github/workflows/` para que no corra)
con `SonarSource/sonarqube-scan-action` y `-Dsonar.qualitygate.wait=true`: analiza todas las ramas y el trabajo FALLA si la puerta falla.

**Pasos de activación (los hace el dueño):**
1. En SonarCloud → Administration → Analysis Method: **desactivar el análisis automático** (con los dos activos, SonarCloud rechaza el del CI).
2. Crear un token de SonarCloud y guardarlo como secreto de GitHub `SONAR_TOKEN` (Settings → Secrets and variables → Actions). Nunca en el repositorio.
3. Mover el borrador a `.github/workflows/sonar.yml`, fijar la acción por SHA y comprobar el nombre de la organización y la clave del proyecto
   (el borrador usa `thekion11` y `thekion11_Dinastia`, vistos en la API pública de SonarCloud; no se han probado con el escáner).
4. Si el análisis del CI usa `sonar-project.properties`/`.sonarcloud.properties`, repetir allí las exclusiones (`terceros/**`).

**Ventajas.** Ramas sin PR analizadas; el CI en rojo cuando la puerta falla (antes: solo comentario del bot); cobertura/informes propios si se añaden.
**Riesgos y costes.**
- Un PR de una bifurcación no recibe el secreto: ese análisis falla (el repo hoy no tiene PR de forks, confirmar).
- Cada push añade ~2-5 min de ejecutor (sin pruebas del juego; solo el escáner). Con `paths-ignore` (propuesta aparte) los pushes de solo documentos no lo lanzarían.
- Si el token caduca o falta, todos los pushes quedan en rojo hasta renovarlo.
- Mientras el análisis automático siga activo el escáner del CI falla («automatic analysis is enabled»): el orden de los pasos 1→3 importa.
- Cambiar el modo reinicia el historial de "código nuevo" si se cambia la rama de referencia; no cambiarla.
**Recomendación:** activarlo solo cuando el repositorio esté en 0 issues abiertos en `main` (hoy se persigue por PR), para que el primer análisis no deje todo en rojo.
