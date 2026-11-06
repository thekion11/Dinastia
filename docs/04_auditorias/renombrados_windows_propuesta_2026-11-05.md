# Renombrado propuesto para poder clonar en Windows (5-11-2026) — NADA renombrado, decide el dueño

Auditoría de TODOS los archivos versionados (`git ls-files`) contra las reglas de Windows: nombres con `< > : " | ? *`, terminados en punto o
espacio, nombres reservados (CON, NUL, COM1…), colisiones de mayúsculas y rutas largas.

| Comprobación | Resultado |
|---|---|
| Caracteres o nombres no válidos en Windows | 0 |
| Colisiones por mayúsculas/minúsculas | 0 |
| Rutas > 150 caracteres | **1** |

## El único archivo
- Ruta actual (255 caracteres; nombre de 216):
  `material/escudos_especiales_originales/@juventus x @adolfodmzm Logo Redesign NEW LOGO JUVENTUS FC ⚪️⚫️🐂  ¿Tú qué opinas_ SI O NO_  — #juventus #juventusfc #bianconeri #forzajuve #seriea #finoallafine #logoredesign #futbol #futboldiseño #sportsbranding.jpg`
- Con el prefijo de un checkout típico (`D:\a\Dinastia\Dinastia\`, 22 caracteres) pasa de los 260 de `MAX_PATH` y Git en Windows falla con
  «Filename too long» (hasta que se activa `core.longpaths`; el CI de `plataformas.yml` ya lo activa).
- Además lleva emojis y es el nombre de un vídeo de TikTok, no un nombre de archivo.

## Propuesta exacta (un solo `git mv`)
```
git mv "material/escudos_especiales_originales/@juventus x @adolfodmzm Logo Redesign NEW LOGO JUVENTUS FC ⚪️⚫️🐂  ¿Tú qué opinas_ SI O NO_  — #juventus #juventusfc #bianconeri #forzajuve #seriea #finoallafine #logoredesign #futbol #futboldiseño #sportsbranding.jpg" \
       "material/escudos_especiales_originales/juventus_redisenio_adolfodmzm.jpg"
```
(La carpeta tiene 111 imágenes más; ninguna otra necesita cambios.)

## Referencias a ese archivo
Búsqueda en todo el repositorio (excluido `.git`/`.godot`) de `adolfodmzm` y de la ruta: **0 referencias** en código, escenas, datos ni
documentos (solo `docs/04_auditorias/LIMPIEZA_RAMAS_2026-11-03.md` menciona la CARPETA, no el archivo). Renombrarlo no rompe nada.
Si el dueño prefiere no tocar `material/`, la alternativa es dejar `core.longpaths=true` documentado para quien clone en Windows.
