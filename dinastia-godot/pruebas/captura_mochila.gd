extends Node3D
## Mochila de los peatones: de espalda, de perfil y de frente (correas). ANTES=1 pone la caja de antes.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1000x700 res://pruebas/captura_mochila.tscn → /tmp/mochila_<antes|despues>.png
var _n := 0

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	Mini3D.caja(self, Vector3(0, -0.1, 0), Vector3(40, 0.2, 40), Mini3D.mat(Color(0.5, 0.5, 0.48)))
	for k in 3:
		var d := PeatonVida.nuevo(self, 61 + k * 7)
		var esq := FutbolistaQ.esqueleto_de(d["nodo"])
		for c in esq.get_children():
			if c is BoneAttachment3D and (c as BoneAttachment3D).bone_name == "spine_03":
				c.queue_free()   ## la mochila que el peatón ya llevaba (la nueva)
		var h := PeatonQ._en_hueso(esq, "spine_03", 1.0 / maxf((d["modelo"] as Node3D).scale.y, 0.01))
		var col := Color(0.2, 0.3, 0.5).lightened(0.15 * k)
		if OS.get_environment("ANTES") == "1":
			PeatonQ._pieza(h, PeatonQ._caja(Vector3(0.26, 0.3, 0.13)), PeatonQ._m(col), Vector3(0, -0.03, -0.16))
			PeatonQ._pieza(h, PeatonQ._caja(Vector3(0.22, 0.13, 0.05)), PeatonQ._m(col.darkened(0.2)), Vector3(0, -0.1, -0.25))
		else:
			MochilaQ.poner(h, col)
		var n := d["nodo"] as Node3D
		n.position = Vector3(-1.1 + float(k) * 1.1, 0, 0)
		Mini3D.anim(d, "caminar", "")
		(d["anim"] as AnimationPlayer).seek(0.15 * float(k), true)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 20, 0)
	add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.74, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.66, 0.7)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.name = "Cam"
	add_child(cam)
	cam.fov = 35.0
	cam.make_current()
	_vista(0)

func _vista(i: int) -> void:
	var cam: Camera3D = get_node("Cam")
	var ang: float = [PI, PI / 2.0, 0.0, PI * 0.8][i]
	cam.position = Vector3(sin(ang), 0, cos(ang)) * 3.4 + Vector3(0, 1.3, 0)
	cam.look_at(Vector3(0, 1.2, 0), Vector3.UP)

func _process(_d: float) -> void:
	_n += 1
	var tag := "antes" if OS.get_environment("ANTES") == "1" else "despues"
	var fases := [20, 30, 40, 50]
	for i in 4:
		if _n == fases[i]:
			get_viewport().get_texture().get_image().save_png("/tmp/mochila_%s_%d.png" % [tag, i])
			if i < 3:
				_vista(i + 1)
	if _n > 55:
		get_tree().quit()
