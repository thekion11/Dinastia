# Cómo se interpretan los resultados de SonarCloud (regla fija, 5-11-2026)

Origen: orden del dueño tras el ciclo del 5-11 (de 492 a 0 issues abiertos en `main`). Informe y gestión del día: `04_auditorias/sonar_2026-11-05.md`.

## Qué cuenta como «bien»
- **Puerta de calidad en verde** en cada PR («0 New issues», 0 hotspots sin revisar). Sin ella no se fusiona.
- **0 issues abiertos en `main`**. Los que no se pueden cerrar con código los acepta el dueño en la web de SonarCloud (ver abajo), con comentario.
- Sonar en verde **no prueba** que el juego funcione, ni el banco/especiales prueban que Sonar esté limpio: se exigen los dos. La cobertura sale 0,0 % porque Sonar no mide GDScript; la puerta no la exige.

## Un aviso es una afirmación que se verifica, no una orden
1. Trazar un camino realista hasta el fallo. Ni arreglar a ciegas ni silenciar a ciegas.
2. Arreglar por **causa**, de mayor a menor severidad, en bloques pequeños con commit y push tras cada uno.
3. **No cambiar el comportamiento del juego para callar un aviso** sin avisar al dueño. Si un arreglo lo cambia, se anota. Tampoco se cambia un generador de azar con semilla fija cuya salida se guarda o se reproduce (p. ej. `biblioteca_caras.py`).

## Qué hacer según el tipo de aviso
| Aviso | Qué se hace |
|---|---|
| Ruta o argumento de línea de comandos (`pythonsecurity` S8707, S8705, S2083, S6549) | `herramientas/ruta_segura.py` en el punto donde se abre el archivo (`open(ruta_segura(x))`). Toda herramienta nueva con rutas por argumento nace con ella. Fuera del repo, directorio actual y temporal hace falta `DINASTIA_RUTAS_PERMITIDAS`. **No** `NOSONAR`: no surte efecto en reglas de flujo de datos. |
| Descarga con direcciones sacadas de una respuesta externa (`pythonsecurity` S5144, S7044) | Solo HTTPS y solo los servidores esperados; la RUTA validada (caracteres permitidos, sin `..` ni `.`, sin consulta) y la dirección REHECHA con la ruta ya validada antes de abrirla (`herramientas/bajar_cc0_modelos.py`, `abrir`). |
| Regex lenta (S8786, S5852) | Reescribir sin ambigüedad y comprobar contra muestras reales (p. ej. todo el GDScript del repo): 0 diferencias. |
| Workflows | Entradas por `env:`, nunca dentro de `run:`; acciones fijadas por SHA; `curl --proto "=https"` con `-f` y reintentos. |
| Azar no criptográfico (S2245) en juego o herramientas | Es un falso positivo. Lo marca el dueño en la web (*Issues → Bulk Change → Change status → Accepted / False positive*, con comentario). Las sesiones no escriben en SonarCloud. |
| Destructores, nulos, fugas, `wait` sin condición… (C++) | Arreglo real; si toca `nativo/src`, recompilar y `probar_nativo.tscn` = «FIN. 0 fallos». |
| `terceros/` | Excluido del análisis por orden del dueño (`.sonarcloud.properties`, `sonar.exclusions`). Para volver a analizarlo, quitar esa línea. |

## `NOSONAR`
Solo con el formato `NOSONAR(regla): motivo` en la propia línea, y solo en reglas que lo admiten. Nunca para esconder un fallo real ni en reglas de seguridad o de flujo de datos.

## Si falla el CI de un PR
No se relanza hasta que pase: se lee el registro completo, se reproduce y se arregla la **causa**. El 5-11 aparecieron 4 pruebas intermitentes (carrera con el explorador, recuento por `get_instance_id()`, azar sin semilla y umbral dentro del ruido); ninguna era un fallo del juego. Se arreglan haciendo la prueba robusta (esperar a la condición, comprobar la regla, umbral fuera del ruido), nunca desactivándola.

## Cómo repetir el ciclo
`SONAR_TOKEN=… python3 dinastia-godot/herramientas/sonar_informe.py` → corregir por severidad → `banco.sh` y `especiales.sh` → PR → análisis de Sonar → repetir. El informe conserva la sección «Gestión» escrita a mano. El token **nunca** va al repositorio.
