class_name CabinaAscensor
extends Node3D
## El hueco de la cabina del ascensor (`PuertasAscensor`): lleva el plano que dibuja la cabina con fondo (`cabina_ascensor.gdshader`). Tiene script
## por lo mismo que `HojaAscensor`: `FundirPiezas.fundir_profundo` no funde lo que cuelga de un nodo con script, y fundido perdería su material.
