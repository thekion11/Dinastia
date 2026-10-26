# assets/ciudad/publico — licencia

- `hincha_<pose>_<nivel>.res`: el modelo humano de Quaternius (CC0) horneado en poses
  quietas (`herramientas/hornear_publico.gd`).
- `hincha_vat_<nivel>.res` (26-10-2026): el mismo modelo en pose sentado + textura de
  vértices (VAT) con 13 clips de medio cuerpo (`herramientas/hornear_publico_vat.gd`).
  Clips: Mesh2Motion, CC0 1.0 (ver `assets/characters/quaternius/anims_m2m/LICENCIA.md`).
  La técnica (fila = fotograma, columna = vértice, filtro nearest) sigue la del plugin
  «Godot Vertex Animation Textures» de antzGames (MIT, 2024); no se copió su código.
- Peso: ~530 KB las tres mallas VAT; son `.res` y no van por LFS (no hace falta excepción
  en `.gitattributes`).
