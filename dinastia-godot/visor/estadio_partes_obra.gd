class_name EstadioObra
extends RefCounted
## LA OBRA DEL ESTADIO (FASE 0, 25-10-2026). Lo que `StadiumBuilder.build()` calcula una vez al empezar
## -la forma, las medidas, los materiales compartidos- y lo que cada zona necesita leer. Antes viajaba
## como un Array de 13 posiciones entre `build_1` y `build_2` (y 17 parámetros sueltos); ahora cada
## zona (`_levantar_tribuna`, `_esquinas`, `_vallas`, `_fachada_y_escudo`…) recibe esta obra.
## Solo datos: quien construye sigue siendo `StadiumBuilder`.

var root: Node3D
## El perfil del estadio (copia con la ropa de la hinchada si hubo club; ver `_preparar_obra`).
var est: Dictionary
var cap_efectiva: int
var ocupacion: float
var seed_val: int
var mi: Club

## Geometría de la forma (`geom_de_forma`): semiejes de la cara interior y tribunas que faltan.
var g: Dictionary
var dz: float
var dx: float
var abierta: int
var abiertas: Array
## La tribuna de honor con una bandeja más (-1 = ninguna).
var principal: int
## Dónde cruza el túnel la tribuna del fondo +Z (-1000 = sin túnel).
var tunel_x0: float

var niveles: int
var alto: float
var techo: String
var techo_col: String
var fondo_trib: float
## Inclinación del graderío (radianes) y lo que sube cada bandeja.
var ang: float
var subida_b: float

## La fachada de hormigón, el techo y la grada compartidos (cada tribuna puede pedir los suyos).
var stand_mat: StandardMaterial3D
var roof_mat: StandardMaterial3D
var crowd_mat: StandardMaterial3D

## Los paños exteriores que cada tribuna y esquina deja para `FachadaEstadio`.
var caras_fachada: Array = []


## UNA TRIBUNA EN OBRA: lo que la tribuna `i` resolvió de su estilo y de su tamaño.
class Tribuna:
	## 0 = fondo sur (+Z), 1 = fondo norte (-Z), 2 = lateral este (+X), 3 = lateral oeste (-X).
	var i: int
	## Centro real de la tribuna, tamaño y hacia dónde mira (apunta al campo).
	var pos: Vector3
	var size: Vector3
	var cara: Vector3
	var lateral: bool
	## Bandejas, alto y fondo de ESTA tribuna (la de honor lleva una más).
	var niv_s: int
	var alto_s: float
	var fondo_s: float
	## Su estilo propio en `est["bandejas"]` ({} = el global) y lo que sale de él.
	var estilo: Dictionary
	var asiento_p: String
	var techo_i: String
	var est_s: Dictionary
	var tramos_i: Array
	## Tres tercios propios (`est["tramos"]`): textura de punta a punta, sin repetir.
	var es_tramo: bool
	## La tribuna del túnel deja un hueco en el muro, el zócalo y la primera bandeja.
	var hueco: bool
	var quiere_techo: bool
