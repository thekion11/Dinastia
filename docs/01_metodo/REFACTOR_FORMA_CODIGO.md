# Refactor de la forma del código (orden 63, 20-11-2026)

Orden del dueño: corregir **cada** aviso del análisis de código (`docs/PLAN_GENERAL.md`, «DETECCIÓN DE FALLOS DE TODO EL CÓDIGO»), por pequeño que sea,
**sin cambiar cómo se juega**. Esta guía es el método. Léela entera antes de tocar nada y lee `CLAUDE.md` (reglas fijas).

## Qué hay que arreglar (cifras del 20-11)

| Aviso (`analizar_gd.py ast`) | Umbral | Cantidad |
|---|---|---:|
| `ast:complejidad-ciclomatica` | complejidad > 15 | ~556 |
| `ast:funcion-larga` | más de 80 líneas | ~438 |
| `ast:muchos-parametros` | más de 6 parámetros | ~218 |
| `ast:anidamiento` | anidamiento > 5 | ~152 |
| `gdlint:max-returns` | demasiados `return` | ~53 |
| `gdlint:max-public-methods` | clase con demasiados métodos públicos | ~17 |

Cómo sacar TU lista (solo los archivos de tu bloque; el análisis tarda ~20 s):

```
pip install gdtoolkit
python3 dinastia-godot/herramientas/analizar_gd.py ast /tmp/ast.jsonl
python3 - <<'EOF'
import json,collections
for l in open("/tmp/ast.jsonl"):
    h=json.loads(l)
    if h["archivo"].startswith("dinastia-godot/nucleo/") and h["regla"] in ("ast:complejidad-ciclomatica","ast:funcion-larga","ast:muchos-parametros","ast:anidamiento"):
        print(h["regla"],h["archivo"],h["linea"],h["mensaje"][:60])
EOF
```
(`gdlint archivo.gd` da los de `max-returns` y `max-public-methods`.) Ordena por gravedad: primero complejidad > 30, después largas, parámetros, anidamiento.

## Reglas (no negociables)

1. **Mismo comportamiento.** Es un refactor, no un arreglo ni una mejora. Mismas operaciones, mismo orden, **mismo uso del azar** (`Azar`, `rng`: no cambiar el orden ni el número de tiradas) y mismos textos. Si encuentras un fallo real, anótalo en `PLAN_GENERAL.md` («FALLOS DETECTADOS») y NO lo mezcles con el refactor.
2. **Ningún script > 450 líneas** (`python3 herramientas/revisar_lineas.py`: mira la SALIDA, no el código de salida). Partir un archivo: `herramientas/partir_gd.py`. Cuidado: con un archivo que YA es una capa (`x.gd` que hace `extends "res://…/x_p1.gd"`) la herramienta lo rompe; ahí crea a mano una capa intermedia `x_p2.gd` (extiende `x_p1.gd`) con las funciones que sobren y haz que `x.gd` extienda `x_p2.gd` (así se hizo con `idiomas_p2.gd` y `partida_p2.gd`). Los `.gd.uid` nuevos se suben.
3. **Archivos GENERADOS: no se editan a mano** (la cabecera dice «Generado por …»: `dialogos_ciudad.py`, `montar_narracion.py`, etc.). Se cambia el generador y se regenera (`dialogos_ciudad.py --solo-gd` no toca `datos/idiomas_extra.json`).
4. **Gemelas C++ (regla de la extensión).** Si la función tiene gemela en `dinastia-godot/nativo/src` (la versión C++), el GDScript es su gemela exacta: refactorízala SOLO si `pruebas/probar_nativo.tscn` sigue en «FIN. 0 fallos»; si cambias lo que hace, hay que cambiar las dos y recompilar. Las funciones `<nombre>_gd` y los envoltorios `Nativo.de("nuc_…")` NO se tocan.
5. **Regla de memoria del menú:** el menú no nombra clases de la ciudad, del estadio/partido 3D ni de las pantallas perezosas (usar `load("res://…")` o las constantes `_RUTA_*` ya existentes).
6. **Lo que el dueño ya decidió se respeta:** nada de ideas nuevas, nada de quitar funciones sin decirlo.
7. Hablar al dueño solo en español; commits sin identificadores de modelo; sin PR; sin tocar ramas `borrar-*`, `entregas/`, `marca/`.

## Cómo partir cada tipo de función

* **`match` enorme (muchos casos, todos con `return`)** → `herramientas/partir_match.py <archivo> <función> [8]` (ver su cabecera). Valida SIEMPRE.
* **Función larga con pasos consecutivos** → extrae cada paso a una función auxiliar privada `_<función>_<paso>` y deja la original como una lista de llamadas. Lo que un paso necesita se pasa como parámetro; lo que produce se devuelve (un `Dictionary` o un `Array` si son varios valores). Cuidado con las variables que se modifican en varios pasos: pásalas y devuélvelas.
* **Muchos `if`/`elif`** → tablas (`const`/`Dictionary`) o funciones auxiliares por rama; cláusulas de guarda (`if not X: return`) para quitar niveles.
* **Anidamiento** → cláusulas de guarda y `continue` en los bucles; extraer el cuerpo del bucle interior a una función.
* **Más de 6 parámetros** → agrupar los opcionales en un `Dictionary` `opc` con valores por defecto documentados (como `_mesa_con_sillas`), o agrupar los que viajan juntos (como `look` en `PlayerSpawner._crear_jugador`). Si la función tiene varias llamadas, reescríbelas TODAS (busca con `grep -rn "\bnombre(" dinastia-godot`).
* **Muchos `return`** → una variable de resultado, o extraer; no cambies la lógica.
* **Clase con demasiados métodos públicos** → mover un grupo de métodos a un script auxiliar de funciones estáticas, o a una capa de herencia.
* En los auxiliares **conserva la inferencia de tipos**: si el original hacía `var m := p.mundo`, el auxiliar vuelve a declararlo igual (si lo recibe como parámetro sin tipo, `var x := m.algo()` falla con «Cannot infer the type»). Un auxiliar que puede «no hacer nada» devuelve `Variant` (`null` = no aplica).
* Trampas ya vistas: `gdparse` hay que lanzarlo desde la RAÍZ del repo (desde otra carpeta da «NO LEE» falso); `gdlint` no admite variables locales que empiecen por `_` ni nombres en MAYÚSCULAS; un `elif` tras un `return` pasa a `if`.

## Verificación (antes de CADA commit)

```
gdparse <archivos tocados>                                   # sintaxis (desde la raíz del repo)
bash dinastia-godot/herramientas/compilar_todo.sh            # «COMPILADOS N, FALLAN 0»: compila TODOS los scripts
bash dinastia-godot/herramientas/banco.sh                    # «===== FIN. 0 fallos =====»
python3 dinastia-godot/herramientas/bancos_especiales.py <banco del área>   # p. ej. menu_navegacion, estadio_3d, partido_jugable…
godot --headless --path dinastia-godot pruebas/probar_nativo.tscn           # «FIN. 0 fallos» (si tocaste algo cercano al motor)
godot --headless --path dinastia-godot pruebas/igualdad_motor.tscn          # «FIN. 0 fallos» (huellas del motor)
python3 herramientas/revisar_lineas.py                       # «pasan de 450 líneas: 0»
```
Usa `XDG_DATA_HOME=$(mktemp -d)` al correr pruebas (una prueba de accesibilidad deja `escala=1.6` en las preferencias).
**Fallos conocidos que ya fallaban antes de este trabajo (no son tuyos):** `pruebas/igualdad_mundo.tscn` (huella guardada), y en `menu_navegacion`: atajos de teclado, presupuesto del recorrido, pruebas visuales y los 6 rieles; en `personajes_3d`: modelos con LOD; `vis_partido_*`/`ren_partido_presupuesto` piden Vulkan. Si un banco te da un fallo que NO está en esta lista, compruébalo contra `main` antes de seguir (copia limpia con `git worktree add`).
**Pruebas y capturas:** si refactorizas un script de `pruebas/`, ejecútalo (o su escena) y confirma que da lo mismo que antes; las capturas necesitan pantalla y se saltan sin xvfb.
Para una función pura que devuelva texto o números, **compara con la versión de `git`** (`git show HEAD:ruta`, copia sin `class_name` con otro nombre, mismas entradas, `var_to_bytes` o `==`) y borra el script temporal.

## Flujo de trabajo

* **(21-11, regla vigente)** Cada sesión empuja SOLO a su rama `refactor-forma-sesion-<letra>-<carpeta>` (`git push -u origin <rama>`) cada 3-5 funciones verificadas, y avisa a la líder con `send_message` a `@parent`; **la líder verifica (compilar_todo, banco, probar_nativo, igualdad_motor, líneas) y fusiona a `main`**. El control de permisos deniega a las sesiones hijas empujar a `main`, y lo que no está en una rama remota se pierde si el contenedor se reclama. Sin PR, sin force push. Si `main` avanza: `git fetch origin main && git merge origin/main` en tu rama y repite banco + `compilar_todo`. Sin identificadores de modelo en los mensajes de commit. El límite de uso de 5 h es de TODA la organización: lecturas pequeñas y no repetir el banco entero tras cada cambio mínimo.
* Commit y push cada ~10 funciones (bloques pequeños). Mensaje: qué funciones, que el comportamiento no cambia, y las comprobaciones que pasaron.
* Cada sesión toca **solo los archivos de su bloque** (para no pisarse): si una firma cambia, corrige las llamadas aunque estén en otro bloque, con el cambio mínimo, y mira `git status` antes del merge.
* Si `main` avanza y hay conflicto: resuélvelo conservando lo de la otra sesión; nunca reescribas historia.
* Cuando una función queda arreglada, vuelve a ejecutar `analizar_gd.py ast` para comprobar que ya no sale. Al terminar un bloque, actualiza el apartado «DETECCIÓN DE FALLOS» de `docs/PLAN_GENERAL.md` (BORRA lo hecho, no lo taches) y avisa a la sesión líder con `send_message` (`@parent`): cuántas funciones, cuántas quedan y qué dudas hay.
* Ante la duda de si algo cambia el comportamiento: NO lo toques y anótalo.

## Bloques

| Sesión | Carpeta | Aprox. |
|---|---|---|
| A | `dinastia-godot/nucleo/` (menos lo ya portado a C++: no tocar `<nombre>_gd` ni los envoltorios `Nativo.de`) | ~63 de complejidad + largas/parámetros/anidamiento |
| B | `dinastia-godot/visor/` | ~118 de complejidad + el resto |
| C | `dinastia-godot/ui/` | ~67 de complejidad + el resto |
| D | `dinastia-godot/pruebas/`, `dinastia-godot/herramientas/`, `dinastia-godot/minijuegos/` | ~310 de complejidad + el resto |

La sesión líder (la que creó las demás) sigue con el paso a C++ y, al final, con el estilo (`gdformat`, líneas largas): **ninguna otra sesión toca el estilo**.
