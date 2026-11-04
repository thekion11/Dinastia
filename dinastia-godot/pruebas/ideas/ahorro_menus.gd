extends BaseIdea
## AHORRO EN LOS MENÚS, segunda parte (3-11): los fondos con shader de `TIME` (menús laterales, entrada, logo) se congelan en MÍNIMA/motor ligero para que el modo de bajo consumo sirva.
## `AhorroMenu.shader` devuelve una copia sin `TIME` (mismos uniformes, la misma para cada shader), y con los fondos en movimiento devuelve el shader tal cual. Sin pantalla (el ahorro de
## verdad —fotogramas dibujados con la pantalla quieta— se mide con `zz_medir_menu_gpu.tscn` con PANTALLA=lateral:<id>|inicio|modos|idioma|config).
func _ready() -> void:
	await get_tree().process_frame
	_titulo("AHORRO EN LOS MENÚS · fondos congelados")
	var original := Shader.new()
	original.code = "shader_type canvas_item;\nuniform vec4 c1 : source_color = vec4(1.0);\nuniform float velocidad = 0.5;\nvoid fragment() {\n\tfloat t = TIME * velocidad;\n\tCOLOR = c1 * (0.5 + 0.5 * sin(t + UV.x) + TIME * 0.0);\n}\n"
	var sin_tiempo := Shader.new()
	sin_tiempo.code = "shader_type canvas_item;\nvoid fragment() { COLOR = vec4(1.0); }\n"
	var antes := Calidad.motor_ligero
	Calidad.motor_ligero = false
	_comprobar(AhorroMenu.shader(original) == original, "con los fondos en movimiento el shader no se toca")
	Calidad.motor_ligero = true
	_comprobar(AhorroMenu.fondo_estatico(), "con el motor ligero los fondos van quietos")
	var q := AhorroMenu.shader(original)
	_comprobar(q != original and not q.code.contains("TIME"), "el shader congelado ya no usa TIME")
	_comprobar(q.code.contains("uniform vec4 c1") and q.code.contains("uniform float velocidad"), "y conserva sus uniformes")
	_comprobar(AhorroMenu.shader(original) == q, "es el mismo cada vez (una sola copia por shader)")
	_comprobar(AhorroMenu.shader(sin_tiempo) == sin_tiempo, "un shader sin TIME se deja como está")
	_comprobar(AhorroMenu.shader(null) == null, "sin shader, nada")
	## Que el congelado compila de verdad y acepta los parámetros de antes.
	var m := ShaderMaterial.new()
	m.shader = q
	m.set_shader_parameter("velocidad", 0.2)
	_comprobar(float(m.get_shader_parameter("velocidad")) == 0.2 and q.get_shader_uniform_list().size() == original.get_shader_uniform_list().size(), "los parámetros siguen funcionando")
	## Los de verdad: todos los shaders de fondo con TIME del menú se congelan sin perder uniformes.
	for ruta: String in ["res://ui/fondo_menu.gdshader", "res://ui/entrada/idioma_fondo.gdshader", "res://ui/entrada/idioma_bandera.gdshader", "res://ui/entrada/pais_bandera.gdshader",
			"res://ui/entrada/config_club_fondo.gdshader", "res://ui/entrada/menu_modos_logo.gdshader"]:
		var sh := load(ruta) as Shader
		var f := AhorroMenu.shader(sh)
		_comprobar(not f.code.contains("TIME") and f.get_shader_uniform_list().size() == sh.get_shader_uniform_list().size(), "%s se congela sin perder uniformes" % ruta.get_file())
	## El globo de la pantalla de país: en MÍNIMA se queda quieto (una pasada de dibujo) y despierta al tocarlo.
	var globo := Globo3D.new()
	add_child(globo)
	globo.size = Vector2(600, 300)
	for i in 120:
		await get_tree().process_frame
	_comprobar(globo._reposo and globo._viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS, "en MÍNIMA el globo se queda quieto y deja de repintarse")
	var lon0: float = globo.lon
	for i in 20:
		await get_tree().process_frame
	_comprobar(globo.lon == lon0, "y no deriva solo")
	globo.ir_a("ESP")
	_comprobar(not globo._reposo and globo._viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "al elegir un país vuelve a repintarse")
	for i in 240:
		await get_tree().process_frame
	_comprobar(globo._reposo and absf(globo.lon - float(Globo3D.GLOBO_PAIS["ESP"].x)) < 1.0, "llega al país y vuelve a quedarse quieto")
	Calidad.motor_ligero = false
	for i in 30:
		await get_tree().process_frame
	var lon1: float = globo.lon
	for i in 30:
		await get_tree().process_frame
	_comprobar(not globo._reposo and globo.lon != lon1, "con los fondos en movimiento el globo vuelve a girar solo")
	Calidad.motor_ligero = antes
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
