class_name VelocidadesPartido
extends RefCounted
## LAS VELOCIDADES DEL PARTIDO EN VIVO: milisegundos por minuto de juego. Salieron de `PartidoVivo` porque Ajustes las enseña (el selector «velocidad de partido por
## defecto») y, viviendo allí, abrir Ajustes → Juego compilaba el partido en vivo entero (~1,1 s sin GPU; `recorrido_pantallas`, M-287). `PartidoVivo.VELOCIDADES` sigue existiendo.

## La pausa es la primera porque es la que más se usa: es cuando se piensa el cambio.
const LISTA := [
	{"txt": "Pausa", "ms": 0.0},
	{"txt": "Lento", "ms": 600.0},
	{"txt": "Normal", "ms": 250.0},
	{"txt": "Rápido", "ms": 80.0},
]
