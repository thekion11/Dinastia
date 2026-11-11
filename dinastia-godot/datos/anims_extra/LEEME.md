# Animaciones EXTRA de locomoción (motor League, fase 4)

Cada archivo `*.json` de esta carpeta suma clips al catálogo (`visor/league_catalogo.gd`); la elección de arranques, frenadas y
giros (`LeagueMovimiento.elegir`) los ve igual que a las 49 del original. No hay que tocar código. Sin archivos, todo es como antes.

```json
{
  "biblioteca": "res://assets/characters/quaternius/anims_extra/mi_pack.res",
  "clips": [
    {"nombre": "ext_giro_trote_135", "clip": "Jog_Turn_135", "clip_espejo": "Jog_Turn_135_L",
     "entra": 3.5, "sale": 3.5, "ang": 2.356, "cuerpo": 2.4, "cuerpo_ini": 0.0,
     "largo": 0.45, "pie": "D", "pasos": 2, "reposo": 1, "v_entra": 3.4, "v_sale": 2.8}
  ]
}
```

| Etiqueta | Qué es | Obligatoria |
|---|---|---|
| `nombre` | único, empieza por `ext_` (nombre en la biblioteca del jugador) | sí |
| `clip` | nombre en la `biblioteca` (por omisión, el `nombre`); sus pistas deben usar los huesos de nuestro esqueleto | no |
| `clip_espejo` | el mismo movimiento hacia el otro lado: se registra como `<nombre>_espejo` con ángulos y pie cambiados | no (sin él, no hay versión espejo) |
| `entra`, `sale` | velocidad de entrada y salida: 0 · 3,5 · 5 · 8 m/s (se cuantiza: 0 / <1,8 · <4,4 · <6,2 · resto) | sí |
| `ang` | hacia dónde sale, respecto a como entra, en **radianes**, + a la izquierda | sí |
| `largo` | duración en segundos (0,05 a 3) | sí |
| `cuerpo`, `cuerpo_ini` | giro del cuerpo respecto a la marcha al acabar / al empezar (rad). `cuerpo` por omisión = `ang` | no |
| `pie` | con qué pie empieza: `D`, `I` o vacío | no (`D`) |
| `pasos` | pasos que da el clip (par: acaba con el mismo pie) | no (1) |
| `reposo` | 1 si acaba con el cuerpo en reposo (parado o paso estable) | no (1) |
| `v_entra`, `v_sale` | velocidad real medida en el clip (m/s); guía el movimiento real (`LeagueGuia`) | no (= `entra` / `sale`) |

El tipo (`arranque`, `frenada`, `giro`, `cuerpo`, `paso`) se deduce de esas etiquetas. Una entrada mal etiquetada se rechaza con su
motivo en el registro (`push_warning`). Con un empate gana siempre el clip del original. Prueba: sección «MOTOR LEAGUE: CATÁLOGO
ETIQUETADO Y EXTENSIBLE» del banco. La búsqueda general por etiquetas es `LeagueCatalogo.buscar(filtro, deseo)`.
