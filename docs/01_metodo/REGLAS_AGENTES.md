# REGLAS PARA AGENTES QUE TRABAJAN EN PARALELO EN DINASTÍA (24-10-2026)

Proyecto: «Dinastía», juego de gestión/carrera de fútbol en Godot 4.7.2 (GDScript). Repo: /home/user/Dinastia, juego en
/home/user/Dinastia/dinastia-godot (nucleo/ lógica, ui/ interfaz, visor/ 3D, datos/ tablas, pruebas/ pruebas).
Escribe código, comentarios y tu informe en ESPAÑOL. Lee también /home/user/Dinastia/CLAUDE.md (reglas del dueño).
Objetivo del dueño: «quiero que el juego quede ULTRA PULIDO». Calidad > cantidad. Nada a medias: lo que empieces, termínalo
y compruébalo; si no da tiempo, deja el juego como estaba.

## Hay varios agentes trabajando A LA VEZ en el MISMO árbol (y otras sesiones en otras máquinas, cada una en su rama). Reglas de convivencia (obligatorias)
1. SOLO editas los archivos de TU ZONA (te la doy en tu tarea). Puedes LEER todo. Si necesitas cambiar un archivo de otra
   zona, NO lo hagas: descríbelo en tu informe final («necesito en X:línea …») y yo lo coordino. Archivos nuevos: créalos
   dentro de tu zona o con un prefijo propio.
2. GODOT: la máquina tiene 4 núcleos; TODA ejecución de godot va con el candado: `dinastia-godot/herramientas/turno.sh <comando>` (3 plazas; ANTES era `flock /tmp/godot.lock`, ya no se usa).
   Úsalo con mesura (cada minuto que lo tienes, los otros 39 esperan): pruebas cortas y dirigidas, no el banco entero
   en cada cambio.
3. ANTES de ejecutar nada tras editar un .gd, comprueba que parsea (un error de sintaxis en un archivo compartido rompe
   las pruebas de TODOS):
   `cd /home/user/Dinastia/dinastia-godot && dinastia-godot/herramientas/turno.sh timeout 200 godot --headless --path . --check-only --script res://<ruta>.gd 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -a -A1 "Parse Error" | head`
   (si sale «Parse Error» con línea → arréglalo YA; «Failed to compile depended scripts»/«Identifier not found: Datos» es
   ruido del modo --check-only y se ignora). Si un godot se cuelga, mátalo por PID (nunca `pkill -f`).
4. PRUEBAS: 
   - Pruebas nuevas: NO añadas secciones al banco (banco_p*.gd están reservados). Crea pruebas INDEPENDIENTES en
     `dinastia-godot/pruebas/ideas/<tu_prefijo>_<tema>.gd` + `.tscn` (copia `pruebas/ideas/_plantilla.gd/.tscn`;
     heredan de `BaseIdea`: `_titulo`, `_comprobar(cond, "texto")`, `_mundo(semilla)`) y ejecútalas con
     `dinastia-godot/herramientas/ideas.sh <nombre>` (ya toma el candado; código 0 = «FIN. 0 fallos»). Tras crear una
     clase nueva (`class_name`), reimporta: `dinastia-godot/herramientas/turno.sh godot --headless --path dinastia-godot --import >/dev/null 2>&1`.
   - Grupos del banco existente (rápidos): `dinastia-godot/herramientas/turno.sh dinastia-godot/herramientas/mini_banco.sh <grupo> /tmp/mb_<tu_prefijo>.txt`
     (grupos: partido, guardado, ciudad, estadio, gestion, competicion, textos). Usa SIEMPRE tu propio archivo de registro.
   - Al terminar tu trabajo: UNA vez el banco entero `dinastia-godot/herramientas/turno.sh dinastia-godot/herramientas/banco.sh > /tmp/banco_<tu_prefijo>.txt 2>&1`
     (≈2-3 min). Si falla una sección que NO tiene que ver con tus archivos, es de otro agente: anótalo y no lo toques.
   - Prohibido: tautologías («x or true»), saltarse/desactivar pruebas, bajar umbrales para que pasen.
5. VISUAL: lo visual se revisa en Forward+ con la cámara real (`dinastia-godot/herramientas/captura.sh`, lee su cabecera;
   va con `flock /tmp/godot.lock`). Las capturas se generan en dinastia-godot/pruebas/capturas/ (ignorada por git):
   MUÉVELAS a /tmp/capturas/<tu_prefijo>/ (JPG). Haz antes/después. Máximo ~6 capturas por agente (son lentas sin GPU).
6. GIT: NO hagas git add/commit/push/stash/checkout de archivos ajenos. Yo hago los commits. Para deshacer TUS cambios usa
   `git diff`/`git checkout -- <tu archivo>` solo sobre archivos de tu zona.
7. NORMA: ningún script > 450 líneas (`python3 /home/user/Dinastia/herramientas/revisar_lineas.py`); si uno tuyo se pasa,
   pártelo (capas por herencia: `herramientas/partir_gd.py`, lee su cabecera) o en clases. Código tipado, mismo estilo que
   el de alrededor (comentarios `##` en español explicando el porqué).
8. TEXTOS de interfaz nuevos: siempre con `Idiomas.t("…")` y con traducción a los 8 idiomas (en, pt, fr, it, de, ca, pl, tr):
   escribe un parche JSON y súmalo con `cd /home/user/Dinastia && python3 herramientas/sumar_traducciones.py /tmp/trad_<tu_prefijo>.json`
   (formato en la cabecera del script; NUNCA edites datos/idiomas_extra.json a mano). Hay una prueba que exige que todo
   `Idiomas.t("literal")` esté traducido en los 9 idiomas.
9. Reglas del dueño: datos reales solo en pack_real.json; nombres/marcas ficticios; nada de religión/política real ni romances
   de jugadores reales; sin archivos nuevos en LFS; no quitar ni apagar nada sin decirlo; las caras reales (recursos/caras_*)
   y sus colores de piel NO se tocan; la Carrera de Jugador se toca «con muchísimo cuidado».
10. INFORME FINAL (tu última respuesta): archivos cambiados/creados, qué mejoraste y cómo lo comprobaste (pruebas, capturas en
   /tmp/capturas/…), resultado del banco entero, lo que dejaste sin hacer y por qué, y peticiones a otras zonas.
   Sé honesto: si algo no quedó bien, dilo.
