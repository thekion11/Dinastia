# Memoria del proyecto Dinastía (para Claude)

Se lee al empezar cada sesión. Corta a propósito. Historia completa de órdenes y hallazgos:
`docs/06_historial/memoria_claude_2026-10-24.md`. Índice de docs: `docs/00_INDICE.md`. Método: `docs/01_metodo/METODO.md`.
Tareas abiertas: `docs/03_estado/TABLERO.md`. Actualizar este archivo solo con reglas u órdenes vigentes nuevas.

## Reglas fijas
- Responder en español. Trabajar solo en la rama asignada; nada de PR salvo que se pida. Commit y push tras cada bloque.
- Sin identificadores de modelo en commits ni archivos. Keystore: contraseña NUNCA en el repo. Sin subidas NUEVAS a LFS
  (no tocar ni mover lo ya en LFS: los originales solo están en GitHub). `*.zip`, `.avi`, `.mp4` nunca al repo.
- Datos reales solo en `pack_real.json`; el resto con nombres ficticios y política ficticia. No atribuir religión ni
  romances a jugadores reales. Keystore, licencias, FPS, música y builds los maneja el dueño.
- Irreversible (borrar ramas, reescribir historia, force push) solo con orden explícita. NO tocar las ramas `borrar-*`,
  `respaldo-historia-2026-10-24` ni `entregas/`, `marca/`, capturas, informes sin su OK. No usar `pkill -f <texto del propio comando>`.
- Ejecutar en primer plano: comandos cortos, en pasos separados.
- Norma de código: **ningún script > 450 líneas** (`herramientas/revisar_lineas.py`, `pruebas/comprobar_scripts.gd`). Código nuevo nace
  < 450. Partir con `herramientas/partir_gd.py` (capas por herencia; la última conserva ruta y class_name).
- Antes de SUBIR: `dinastia-godot/herramientas/banco.sh` debe terminar en «FIN. 0 fallos» (corre en paralelo; ~83 s). Mientras se trabaja:
  `mini_banco.sh <grupo>`. Lo que el banco no ve: `dinastia-godot/herramientas/especiales.sh [todo]`. Si el banco se cuelga: error de
  sintaxis; debe aparecer «===== FIN». Sección nueva en banco.gd = añadirla a `SECCIONES`.
- Lo visual se revisa en Forward+ y con la CÁMARA REAL del partido (no solo de cerca): `herramientas/captura.sh`. Capturas en JPG.
  No quitar ni apagar nada sin decirlo.
- Contenedor nuevo: `git lfs pull --include="dinastia-godot/**"` ANTES de abrir Godot. Godot 4.7.2 se baja de GitHub releases.
  Clonar con `--single-branch --branch main` (las ramas viejas pesan). Tras clases nuevas: `godot --headless --import`.
- Datos de caras reales fuera de los builds públicos. Legal: la licencia libre cubre la foto, no el derecho de imagen.
- `datos/idiomas_extra.json` (9 idiomas) round-trips con `json.dumps(ensure_ascii=False, indent=1)`; textos nuevos de UI con `Idiomas.t`.
- Diálogos de ciudad y narración se GENERAN (`herramientas/dialogos_ciudad.py`, `montar_narracion.py`): no editar a mano los resultados.
- En el motor del partido, no usar dicts de jugador como clave: usar `p["id"]`.

## Órdenes vigentes del dueño (24-10)
1. MEGAPLAN_REESTRUCTURACION (`docs/02_vision/`): fases 0-6; decisiones validadas (punto 4 = separar `Principal` en clases + cifras fase 4 §9.1).
2. **Lunes (26-10)**: probar Foundry/Azure, abrir red a Wikimedia, arreglar `compilar.yml` (`cd "Dinastía Godot"`), empezar la fase 0 real.
   Hasta entonces: solo fallas, pendientes, mejoras y limpieza.
3. El dueño borra él las 8 ramas viejas (4 originales + 4 `borrar-*`) y la etiqueta `latest`.
4. Mega auditoría 3 hecha el 24-10: `docs/04_auditorias/MEGA_AUDITORIA_3.md`; método Cascada + V en `docs/01_metodo/`.
5. Idiomas: 9 y no sumar más; faltan ~506 frases por traducir.
6. Pendientes de dueño: FPS en hardware real, builds, keystore, licencias, subir binarios a Drive (`herramientas/drive_subir.ps1`).
