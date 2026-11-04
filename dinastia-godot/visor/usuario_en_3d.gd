class_name UsuarioEn3D
extends RefCounted
## TU PERSONAJE 3D Y TU CLUB, a mano para la banda de cualquier estadio (la vista del partido no tiene el mundo delante). Los fija el menú en cada refresco.
## Vive aquí, sin dependencias, porque fijarlos en `PersonajeDT` compilaba el personaje 3D entero (vestidor, pelo, cara…) al abrir el menú (memoria, 3-11-2026).
## `PersonajeDT.del_usuario` y `PersonajeDT.club_usuario` siguen existiendo y leen/escriben aquí.
static var aspecto: Dictionary = {}
static var club: String = ""
