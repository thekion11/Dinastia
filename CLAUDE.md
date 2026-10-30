# Memoria del proyecto Dinastía (para Claude)

Se lee al empezar cada sesión. Corta a propósito (la memoria larga se borró el 24-10; sigue en el historial de git).
Índice de docs: `docs/00_INDICE.md`. Método: `docs/01_metodo/METODO.md`. TODO lo pendiente: `docs/PLAN_DEL_LUNES.md`.
Actualizar este archivo solo con reglas u órdenes vigentes nuevas. Lo completado se BORRA de los documentos (no se tacha).

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
  sintaxis; debe aparecer «===== FIN». Sección nueva = función en `pruebas/banco/<grupo>.gd` (o `varios`) + nombre en `SECCIONES` (y `GRUPOS`) de `pruebas/banco.gd`; si falta una, FALLO.
- Lo visual se revisa en Forward+ y con la CÁMARA REAL del partido (no solo de cerca): `herramientas/captura.sh`. Capturas en JPG.
  No quitar ni apagar nada sin decirlo.
- Contenedor nuevo: `git lfs pull --include="dinastia-godot/**"` ANTES de abrir Godot. Godot 4.7.2 se baja de GitHub releases.
  Clonar con `--single-branch --branch main` (las ramas viejas pesan). Tras clases nuevas: `godot --headless --import`.
- Datos de caras reales fuera de los builds públicos. Legal: la licencia libre cubre la foto, no el derecho de imagen.
- `datos/idiomas_extra.json` (9 idiomas) round-trips con `json.dumps(ensure_ascii=False, indent=1)`; textos nuevos de UI con `Idiomas.t`.
- Diálogos de ciudad y narración se GENERAN (`herramientas/dialogos_ciudad.py`, `montar_narracion.py`): no editar a mano los resultados.
- En el motor del partido, no usar dicts de jugador como clave: usar `p["id"]`.
- Extensión C++ (`nativo/src` → `bin_nativo/`, 30-10): cada función es copia exacta de su versión GDScript (que se queda como respaldo para Android/Web). Si se toca una de las dos, recompilar (`herramientas/compilar_nativo.sh`) y `pruebas/probar_nativo.tscn` debe dar «FIN. 0 fallos».

## Órdenes vigentes del dueño (24-10)
1. Fases 0-6 del guion y decisiones validadas (punto 4 = separar `Principal` en clases + cifras fase 4): en `docs/PLAN_DEL_LUNES.md` §2.
2. **Lunes (26-10)**: Foundry/Azure, red a Wikimedia, imagen Godot 4.7 para el CI, empezar la fase 0 real (`PLAN_DEL_LUNES.md` §1-2).
   Hasta entonces: solo fallas, pendientes, mejoras y limpieza.
3. El dueño borra él las 8 ramas viejas (4 originales + 4 `borrar-*`) y la etiqueta `latest`.
4. Mega auditoría 3 hecha el 24-10 (`docs/04_auditorias/`); método Cascada + V en `docs/01_metodo/`. El 24-10 se borró lo viejo (planes, informes, capturas, vídeos, filas hechas) y el dueño pidió: ideas hechas se revisan «realmente bien», no solo «decentes»; lo no cerrado vive en el plan del lunes.
5. Idiomas: 9 y no sumar más. Las ~506 frases pendientes se tradujeron el 26-10 (sesión 1); lo nuevo, siempre con `sumar_traducciones.py`.
6. Pendientes de dueño: FPS en hardware real, builds, keystore, licencias, subir binarios a Drive (`herramientas/drive_subir.ps1`).
7. LFS (26-10): el dueño autorizó subir los sonidos de interfaz (CC0) y los PNG del logo. Desde este contenedor GitHub rechaza las subidas a LFS: archivos pequeños van fuera de LFS con una excepción en .gitattributes (ya hecha para audio/ui/*.ogg). Nada más sin preguntar.
8. Avisos (26-10): avisar al dueño con un evento de Google Calendar (recordatorio emergente a los 0 min, título «Dinastía: …») cuando haya una pregunta para él, se acaben las tareas, o la otra sesión pida algo o termine. La notificación push no le llega.
9. Sesiones (26-10): coordina y reparte la sesión «Sesiones abiertas» (session_01Vh9g2WJE8b9XRhTkoJQkJC). La sesión de trabajo principal (session_01MtJBCsXzXVcDXqPJ2uAkHW, rama ccr-76d707c5-dwse9h) evalúa, trabaja, une ramas y pregunta ante dudas; las dos se consultan como balanza. Nadie queda parado: al terminar, auditar o pulir del plan.
10. (26-10 noche) Calidad visual: ciudad por zonas (detalle, construcción, coherencia) y personajes (anatomía, movimiento natural,
    más animaciones, profundidad) por PASADAS con captura antes/después y veredicto del dueño; plan en `PLAN_DEL_LUNES.md` §2.2e.
    La sesión líder (session_016d4XAEpSpuptrGg8J4Wene) manda y reparte; la ejecutora (session_01VUJiyfwiM2ZPT2H3gaDzqg) nunca queda parada.
11. (26-10 noche, decisiones del dueño) Fases 1-3 APROBADAS sin jugarlas aún, dejando constancia de que a futuro hay que pulirlas.
    Fusionar a `main` los PR #12 y #13: concedido («funciona»). Borrar capturas e informes viejos de `dinastia-godot/`: concedido
    (hecho: `pruebas/capturas` y `docs/informes_extraidos`); `marca/` se CONSERVA (tiene el logo para la animación de la intro).
    Red para Wikimedia/banderas: todavía no. El dueño está cerca de su tope de uso: trabajar en bloques pequeños, guardar y empujar a menudo.

