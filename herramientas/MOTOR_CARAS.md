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

## Biblioteca modular (5-10-2026)

Pedido: «guarda los pelos y las caras que estás creando para que los personajes
sean modulares (como el personaje que crea el jugador)».

- `biblioteca_caras.py canonical_face_model.obj 12` → 72 caras (6 tonos × 12).
  Cada una MEZCLA 4 jugadores del mismo tono (fotos de frente, boca cerrada, sin
  tapar): textura llevada al mapa UV canónico triángulo a triángulo, mediana por
  píxel y forma media. Nunca es la cara de una persona.
  Salida: `datos/biblioteca_caras.json` + `recursos/caras_biblioteca/`.
  (Ojo: `decodificar` ya devuelve centésimas de cm; no volver a multiplicar.)
- La misma herramienta escribe `datos/biblioteca_pelos.json`: 44 cortes medidos
  (forma, nacimiento, rizo, largo; sin color) por grupo de corte.
- Juego: `visor/biblioteca_caras.gd` (`BibliotecaCaras.para(semilla, piel, pelo)`,
  `cara_de_tono(piel, i)`). Las usan los jugadores sin foto (`PlayerSpawner`, fijas
  por id) y el creador de personaje («Cara» y «Corte medido»; solo cuerpo de hombre).
- Las caras de la biblioteca salen de fotos con licencia libre: quedan FUERA de los
  builds públicos (`export_presets.cfg`), igual que las caras reales.
- Captura: `pruebas/captura_biblioteca.tscn`; creador: `BIBLIO=1 ... captura_personaje_dt.tscn`.

Pasada 3 de pelo: cabeza agachada (cabeceo < -20°) → piel medida en la franja más
clara (frente, nariz) y ganancia hasta ×1,5; corte `melena_rizada` (largo y con
volumen a los lados). Anillo de fundido metido hacia el cráneo (manchas en las sienes).

## Última pasada (5-10-2026)

- EXPOSICIÓN DE LA PIEL (cara y cuerpo, `cara_malla.gdshader` y
  `VestidorQ.exposicion_piel`): `clamp((0,39/l)^0,53, 1, 3)`. Medido contra el
  color guardado («s»): antes las pieles medias/oscuras salían al 64-74 %
  (Kondogbia casi negro de día); ahora 0,85-1,12 de día y 0,91-0,97 en estudio.
  Compensación de saturación mayor en pieles oscuras (`compensar_piel`): salían
  naranjas. Medición repetible: capturas `MOMENTO=dia|estudio` y comparar la
  mejilla iluminada con «s».
- Borde de la cara pegado a la cabeza del cuerpo (`CaraMalla._pegar_borde`); el
  cuerpo solo hunde el centro de la cara. Zona «oreja» del cuerpo más estrecha.
- Pelo: calvo = cabeza afeitada; la oreja nunca lleva pelo; menos brillo (de día
  reflejaba el cielo, azul). Ojos: menos reflejo (los castaños se veían azules).
- Biblioteca: atlas sin raya en el óvalo, sin la luz de las fotos, piel del borde.
- Fotos agachadas: `albedo_limpio(..., agachada=)` quita toda la luz de los rasgos.
