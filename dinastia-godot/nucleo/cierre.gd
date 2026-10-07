extends Node
## (Sin `class_name`: autoload `Cierre`.)
## EL CIERRE LIMPIO (29-9-2026, auditoría). Al cerrar el juego Godot hacía
## «segmentation fault» (señal 11, en un `pthread_mutex_lock` de la limpieza
## final): las cachés `static var` de texturas, mallas, materiales y shaders
## se liberaban DESPUÉS de apagar el servidor de render. Este autoload las
## vacía en su `_exit_tree`, que corre mientras los servidores siguen vivos.
## Si se añade una caché estática nueva con recursos, va en esta lista.
const CACHES := [
	["res://nucleo/genero.gd", "_reglas", []],
	["res://nucleo/historia_club.gd", "_indice", {}],
	["res://nucleo/historia_club.gd", "_indice_de", null],
	["res://nucleo/historia_club.gd", "_clasicos", {}],
	["res://nucleo/historia_club.gd", "_clasicos_de_tabla", null],
	["res://nucleo/nombres.gd", "_vetados", {}],
	["res://nucleo/partido.gd", "ctx_moda", {}],
	["res://nucleo/partido.gd", "ex_de_mi_club", {}],
	["res://nucleo/reales.gd", "_indice", {}],
	["res://ui/aviso.gd", "_cola", []],
	["res://ui/cara.gd", "_cache", {}],
	["res://ui/cara.gd", "_indice_fotos", {}],
	["res://ui/cara.gd", "_creditos_fotos", {}],
	["res://ui/cara_dt.gd", "_cache", {}],
	["res://ui/casa_naturaleza.gd", "_sh", {}],
	["res://ui/componentes/mentor_voz.gd", "_cola", []],
	["res://ui/componentes/telefono.gd", "_sombra_circulo", null],
	["res://ui/disenos_kit.gd", "_cache", {}],
	["res://ui/disenos_kit.gd", "_silueta", null],
	["res://ui/escudo.gd", "_cache_especial", {}],
	["res://ui/escudo.gd", "_cache", {}],
	["res://ui/fondo.gd", "_cache", {}],
	["res://ui/fondo_animado.gd", "_punto", null],
	["res://ui/fondo_animado.gd", "_raya", null],
	["res://ui/fondo_animado.gd", "_cuadro", null],
	["res://ui/fondo_particulas.gd", "_punto", null],
	["res://ui/inicio.gd", "_brillo_panel", null],
	["res://ui/jersey.gd", "_cache_svg", {}],
	["res://ui/jersey.gd", "_cache_real", {}],
	["res://ui/marca.gd", "_cache", {}],
	["res://ui/portada.gd", "_cache", {}],
	["res://ui/principal.gd", "_brillo_panel", null],
	["res://ui/principal.gd", "_muestras", {}],
	["res://ui/principal.gd", "_fuentes", {}],
	["res://ui/sorteo.gd", "_cache", {}],
	["res://ui/sorteo_escena3d.gd", "_tex_balon", null],
	["res://ui/sponsor_kit.gd", "_cache", {}],
	["res://ui/tarjeta_modo.gd", "_cache", {}],
	["res://visor/anim_extra.gd", "_categorias", {}],
	["res://visor/anim_extra.gd", "_cache_espejo", {}],
	["res://visor/anim_futbol.gd", "_cache", {}],
	["res://visor/anim_quaternius.gd", "_packed_ual", null],
	["res://visor/anim_quaternius.gd", "_lib_ual", null],
	["res://visor/anim_quaternius.gd", "_cache_futbol", {}],
	["res://visor/anim_quaternius.gd", "_cache_futbol_global", {}],
	["res://visor/anim_quaternius.gd", "_cache_recortes", {}],
	["res://visor/balon_3d.gd", "material_actual", null],
	["res://visor/balon_3d.gd", "_cache_tex", {}],
	["res://visor/city_builder.gd", "_mat_blanco", null],
	["res://visor/city_builder.gd", "_mat_bordillo", null],
	["res://visor/city_builder.gd", "_mat_tapa", null],
	["res://visor/futbolista_q.gd", "_packed_male", null],
	["res://visor/futbolista_q.gd", "_packed_female", null],
	["res://visor/kit_texture_factory.gd", "_jersey_cache", {}],
	["res://visor/mascota_q.gd", "_cache_pelaje", {}],
	["res://visor/pelo_q.gd", "_cabeza_femenina", null],
	["res://visor/pelo_q.gd", "_mallas", {}],
	["res://visor/pelo_q.gd", "_nodos", {}],
	["res://visor/pelo_q.gd", "_mats", {}],
	["res://visor/persona_realista.gd", "_escena", null],
	["res://visor/persona_realista.gd", "_mats", {}],
	["res://visor/precipitacion.gd", "_tex_copo", null],
	["res://visor/ropa_separada.gd", "_cache", {}],
	["res://visor/ropa_separada.gd", "_mats", {}],
	["res://visor/stadium_builder.gd", "_malla_hincha", null],
	["res://visor/stadium_builder.gd", "_malla_hincha_det", null],
	["res://visor/stadium_builder.gd", "_butaca_lejos", null],
	["res://visor/stadium_builder.gd", "_escalones", null],
	["res://visor/texturas.gd", "_cache", {}],
	["res://visor/vestidor_q.gd", "_cache_equipacion", {}],
	["res://visor/vestidor_q.gd", "_packed_male", []],
	["res://visor/vestidor_q.gd", "_cache_textura", {}],
	["res://visor/vestidor_q.gd", "_mallas_reposo", {}],
]

func _exit_tree() -> void:
	## La traducción de «entrenadora» es un script registrado en el servidor de
	## traducciones: fuera, antes que nada (era la causa del fallo al salir).
	Genero.desinstalar()
	for fila: Array in CACHES:
		var s: Script = load(String(fila[0]))
		if s != null:
			s.set(String(fila[1]), fila[2])
