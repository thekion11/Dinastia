# Estadios realistas: evaluación de la herramienta y plan (10-11)

Encargo del dueño (vía la sesión líder): recrear estadios reales con el constructor paramétrico, barato en móvil, y una primera tanda de 10 icónicos de 10 países. Nombres y datos reales SOLO en `datos/pack_real.json`; en lo público, el perfil del club con su nombre ficticio.

## 1. Lo que hay hoy

- **Perfil** (`datos/tablas.json` → `EST_DEF`): `forma` (cuenco, oval, rect, caldera, herradura, ingles; internas: dos, principal, estrecho, asimetrico), `niveles` 1-5, `techo` (sin, parcial, anillo, total, membrana, retractil, visera), `pista`, `asientoP` + `asiento1/2/3` (12 patrones), `focos`, `pantalla`, `fachada` (5 materiales) + colores, y por lado `bandeja_<lado>_{asientoP,techo,col1,col2}`, `tramo_<lado>_n`, `anillo_<lado>_n`.
- **Quién lo arma**: `Club.perfil_estadio()` (hash + reputación → estilo `EST_PRESETS` → fila real `ESTADIO_CLUB` por nombre de club), `EstadioPropio.perfil()` para el tuyo; lo dibuja `StadiumBuilder` (capas `_p3` geometría, `_p4` campo/techo, `_p5` niveles, `_p6` butacas y público, `_p7` esquinas/pista, `_p8` focos/exterior/pantallas, `_p10` montaje y fundido en MÍNIMA).
- **Datos reales**: `pack_real.json` → `ESTADIO_CLUB`, 402 clubes con forma, niveles, techo, pista, focos, fachada, `rasgo` (texto) y a veces 2 colores de butaca. Los genera `herramientas/estadios_reales*.py`.
- **Piezas sueltas por texto** (`visor/guinos_estadio.gd`): si `rasgo` dice «techo en arco», «torres rojas», «rampas», «burbujas»… pone una pieza genérica. No es ajustable.
- **Calidad**: en MÍNIMA se funden piezas y hay menos filas y público; en ALTA, bandejas extra a partir de 30.000. No hay medidor de llamadas de dibujo propio del estadio (solo el tiempo de carga, `pruebas/medir_carga_estadio.gd`).

## 2. Lo que falta para recrear estadios reales

| Pieza | Hoy | Falta |
|---|---|---|
| Arco estructural (Wembley, Moses Mabhida) | toro genérico por texto | arco con altura, lado y ángulo como parámetros |
| Cubierta parcial | «parcial» fijo, o por lado con `personalizar_bandejas` | qué lados cubre sin activar todo el modo por lados |
| Gradas desiguales | solo principal/asimetrico | niveles POR LADO (la Bombonera: un lado vertical de palcos) |
| Esquinas | todas o ninguna según la forma | abrir o cerrar esquina a esquina |
| Torres de rampas (San Siro) | guiño por texto | cilindros en las esquinas como parámetro |
| Fachada característica | material y color | celosía/costillas exteriores (Parc des Princes), «colchón» iluminado (Allianz) |
| Pista de atletismo | sí/no | color (azul, roja) |
| Butacas por sector | por lado y anillo; la tabla real trae 2 colores | usar 3 colores y sectores en las filas reales |
| Marcadores | pantallas genéricas | bastan (se usan las existentes) |
| Entorno | `exterior` genérico | queda para después |

## 3. Plan

1. **Piezas nuevas, todas opcionales y con valor por defecto que no cambia nada** (perfil sin la clave = estadio de hoy):
   - `arco`: `{"alto": m, "lado": "norte|sur|este|oeste", "color": hex}` → un arco tubular (pocas caras) sobre el estadio.
   - `techo_lados`: lista de lados cubiertos (p. ej. `["oeste"]`), sin pasar por `personalizar_bandejas`.
   - `niveles_lado`: `{"este": 4, "oeste": 1}` → altura distinta por lado.
   - `torres_rampa`: n.º de cilindros en las esquinas (0, 4, 11…).
   - `fachada_costillas`: costillas exteriores verticales (n.º).
   - `pista_col`: color de la pista.
   - En calidad MÍNIMA: arco y torres sí (son pocas mallas y definen el estadio), costillas no.
2. **Medir**: llamadas de dibujo, nodos y triángulos del estadio antes y después (prueba nueva que construye el estadio sin pantalla y cuenta mallas; captura con la cámara real del partido en Forward+).
3. **10 icónicos de 10 países** en `ESTADIO_CLUB` (solo en el pack real), cada uno con sus piezas y comparado con fotos de referencia y con la captura de la cámara del partido. Primera tanda prevista: Inglaterra (arco), España (cuenco de 3 anillos abierto), Brasil (óvalo con anillo de membrana), Argentina (herradura con un lado vertical), Alemania (colchón iluminado, techo total), Italia (11 torres de rampas y techo rojo), México (cuenco enorme con anillo), Chile (óvalo con pista, techo en un lado), Francia (costillas exteriores), Colombia (óvalo con tribuna cubierta).
