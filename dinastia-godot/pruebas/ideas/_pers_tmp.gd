extends SceneTree
func _init() -> void:
	var c := SphereMesh.new()
	c.radius = 0.118
	c.height = 0.112
	c.is_hemisphere = true
	var a := c.get_mesh_arrays()
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var mn := 9.0
	var mx := -9.0
	for p in v:
		mn = minf(mn, p.y)
		mx = maxf(mx, p.y)
	print("HEMI y ", mn, " .. ", mx)
	quit()
