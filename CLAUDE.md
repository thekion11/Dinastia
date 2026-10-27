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
12. (27-10) Veredicto del dueño sobre las pasadas visuales P1-P3: «MEJORAR». Regalos de Drive: licencia libre y gratuita confirmada
    por él. Órdenes nuevas: el MUSEO tiene que poder EXTENDERSE (por eso el ascensor) con una animación de expansión; la CIUDAD
    ENTERA más completa: muchas partes sin rellenar y RECURSOS SIN USAR (inventario en `docs/04_auditorias/recursos_sin_usar.md`).
    «Lo del museo y rellenar ciudad» va a la sesión ejecutora.
13. (27-10, decisiones del dueño) TÁCTICA: sí, pero en la pasada FINAL del motor, junto con lo visual, la IA de la CPU, el
    comportamiento, el físico, el pasto (regalo `grass.blend` en Drive, a evaluar), las físicas y más sonidos. VEHÍCULOS: suavizar y
    hacer más realistas autos, metro y bus, crear el tren y mejorar el teleférico. TIRO_PULIDO: ENCENDIDO, pero hay que pulirlo más.
    ESTADIOS: separar un poco a los aficionados en las butacas, subir la calidad de las butacas, mejorar los accesos y colorear las
    butacas por nivel según el color del club (y elegible en la personalización del menú inicial).
14. (27-10 tarde, decisiones del dueño) SÍ a clasificar las ~1.200 ideas (lanzamiento / después / descartar). `main` limpio y las
    ramas viejas: el dueño dice que ya lo hizo (verificar). PANTALLA DE ENTRADA nueva: APROBADA. «EL BLOQUEO» de modos: ACEPTADO
    (opción en Ajustes). Las 53 escenas de prueba sin mención: ver qué se puede REUTILIZAR antes de borrar. PEATONES: SÍ suben al
    bus y a los demás transportes. DIFICULTAD DE LA CPU en 8 categorías: Practicante, Cadete, DEBUTANTE (la normal), Semiprofesional,
    Profesional, Experto, Maestro, Ultimate; y además dificultades fuera del partido (eventos, probabilidades, retos, poca ayuda,
    asistentes deficientes, malos consejos y otras). POLICÍA Y BOMBEROS: sí. MUSEO: mejorarlo más y poder INTERACTUAR con los
    trofeos. PELO: usar los cortes y personajes del Drive. Pasadas visuales P1-P3: repetir «MEJORAR». PELUCHES: sí a las
    propuestas (monedas de 1 € del efectivo, una sala en el centro comercial, subir los 14 peluches reducidos fuera de LFS) y además
    COLECCIONABLES que den LOGROS. FPS en PC y móvil: cuando el dueño tenga el equipo listo. Pasto: traerlo del Drive.
15. (27-10 noche, decisiones del dueño) LICENCIAS: el dueño las tiene todas y no se usan fotos de personas en lo público
    (M-421/M-424 cerrados). Carpeta del Drive compartida como lector (pasto, trofeo base, pelo, personaje, foco, garra, silla, sala TV).
    BASE «FICTICIA» DE CLUBES: se queda como está y se COMPLETA: mismas estadísticas físicas y carrera de cada jugador, nombre un
    poco modificado pero reconocible; clubes igual; ESCUDOS que se parezcan más al real; uniformes base iguales; estadio con sus
    colores; los TROFEOS que tenga hoy cada club, modelados a partir del trofeo base del Drive (`gold+trophy.glb`) y modificados
    para parecerse; sus datos guardados en la historia del club. POSICIONES: se quedan en español en todos los idiomas.
    Política de privacidad: publicarla después. PARADEROS: que se parezcan a los de Chile (forma y carteles).
16. (27-10 noche) PELO y PERSONAJES del Drive: licencia confirmada por el dueño. PARADEROS «Red» (nombre basado en Red Movilidad, permitido):
    modelo real en las fotos del dueño (techo blanco con tirantes rojos, cabecera negra «Paradero de Red Movilidad | Parada N» con
    remates rojos y logo, panel publicitario Red, banca de láminas, papelero; POSTE con cartel NEGRO: iconos arriba, nombre de la
    parada, cuadrícula de recorridos en blanco, QR y franja roja abajo). El CÓDIGO del paradero sirve en una APP del móvil: qué micros
    pasan, en cuánto llegan y su patente. Recorridos: números por SECTOR (100: 122, 150, 190; 200: 203, 217, 278…), sufijo «c» =
    sentido contrario, «e» = alternativa (rara); hay también recorridos tipo «C02», «C09c».
