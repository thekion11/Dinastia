# Motor de caras reales (cómo se hacen y cómo mejorarlas)

Pipeline (todo en `herramientas/`, parámetros y lecciones en `motor_caras.py`):

1. `caras_reales_malla.py face_landmarker.task canonical_face_model.obj`
   (modelos de MediaPipe junto a `selfie_multiclass.tflite`; Apache 2.0).
   Por jugador: recorte HD de la cara, malla 3D de su cara (468 + anillo),
   piel/pelo/barba/cejas medidos, exposición y balance de blancos, textura de
   piel REPLICADA (`recursos/caras_reales_albedo/`), color del iris.
   `SOLO="A,B"` prueba con unos pocos; `VER=` / `VER_SEG=` guardan imágenes de control.
2. `auditoria_caras.py` → `dinastia-godot/AUDITORIA_CARAS.md` (marcas automáticas).
3. Hojas de lotes: `LOTE=n godot ... res://pruebas/captura_lote_caras.tscn`
   (12 jugadores por hoja, 96 hojas) → `pruebas/capturas/lotes/` (no se suben).
4. Surtido para mostrar: `caras_variadas.py [semilla]` + `pruebas/captura_caras_reales.gd`.

Juego: `visor/cara_malla.gd(.gdshader)` (malla + textura), `visor/ojos_q.gdshader`
(ojos 3D con el iris medido), `visor/vestidor_q.gd` (`poner_cara`: piel del cuerpo
= tono medido), `visor/pelo_capas.gd` (paso 2: pelo por capas).

Números del juego a tener en cuenta: `COMPENSAR_PIEL` 1,6 (pie del mapeo de tonos),
`exposicion_piel` (solo sube fotos oscuras), cara `quitar_luz` 0 con textura limpia.
