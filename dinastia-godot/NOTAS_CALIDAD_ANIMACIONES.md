# Control de calidad de animaciones

## 20-09-2026 — Mocap UE5 no apto todavía para el partido

La revisión visual encontró un problema que el banco de regresión no mide: los
cinco FBX deportivos se cargan y se reproducen, pero su retarget desde UE5
Manny hacia el rig Quaternius no conserva una silueta humana creíble en los
picos de la acción. El ejemplo más claro es
`pruebas/futbol_real_patear_lado.png`: espalda inclinada hacia atrás y una
pierna que no lee como remate.

También se revisó la patada escrita a mano
(`pruebas/q_patear_disparo_lado.png`). Tampoco alcanza el estándar: termina
como una pose de salto, no como un golpeo de balón.

Decisión aplicada:

- El catálogo normal de `FutbolistaQ` expone exclusivamente locomoción real
  validada: `Idle`, `Walk`, `Jog_Fwd` y `Sprint`.
- Las acciones deportivas quedan marcadas como experimentales y sólo se
  cargan para `pruebas/diagnostico_futbol_real.gd`.
- Ningún partido puede activar esas acciones accidentalmente mientras no haya
  una captura lateral creíble de remate, penal, festejo y atajada.

El siguiente paso es reemplazar la reconstrucción manual de pistas por el
retargeter en tiempo real de Godot con un perfil/bone-map de ambos rigs, o
usar clips que compartan directamente el rig Quaternius. Esta medida protege
el juego de una regresión visual mientras se resuelve la compatibilidad real.
