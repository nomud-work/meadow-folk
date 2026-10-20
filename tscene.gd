## Painted outdoor set: sky shader (gradient + cumulus), grassy hilltop,
## layered far hills with aerial haze, a few lollipop trees, one warm key light.
class_name TScene
extends RefCounted

const KEY := Vector3(0.85, 0.80, 0.35)

static func build(root: Node3D, with_set := true) -> DirectionalLight3D:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	var sh := Shader.new(); sh.code = TShaders.SKY; sm.shader = sh
	sm.set_shader_parameter("sun_dir", KEY.normalized())
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new(); we.environment = env
	root.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.97, 0.90)
	key.light_energy = 0.34
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 6.0
	key.shadow_bias = 0.04
	key.shadow_normal_bias = 1.5
	key.shadow_blur = 1.2
	root.add_child(key)
	key.look_at_from_position(KEY.normalized() * 10.0, Vector3.ZERO, Vector3.UP)
	if with_set:
		_ground(root)
		_far(root)
		_trees(root)
	return key

static func mat(code_name: String, code: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TChar.shader(code_name, code)
	for k in params: m.set_shader_parameter(k, params[k])
	TChar.registry.append(m)
	return m

static func hill_h(x: float, z: float) -> float:
	var r2 := x * x * 0.55 + (z + 0.5) * (z + 0.5)
	return -0.010 * r2 - 0.0007 * r2 * sqrt(r2) * 0.3 + 0.03 * sin(x * 0.7) * sin(z * 0.5)

static func _ground(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var P := func(u: float, v: float) -> Vector3:
		# polar grid: dense near the characters
		var r := 60.0 * pow(v, 2.0)
		var a := u * TAU
		var x := sin(a) * r; var z := cos(a) * r
		return Vector3(x, hill_h(x, z), z)
	Geo.patch(st, P, 96, 60, {"closed_u": true, "orient": func(u, v, p): return Vector3.UP})
	var m := ArrayMesh.new()
	Geo.finish(st, m, mat("GRASS", TShaders.GRASS, {"shade": Color(0.60, 0.66, 0.86), "mid": Color(0.86, 0.90, 0.92), "recv": 1.0}), "ground")
	var mi := MeshInstance3D.new(); mi.mesh = m
	root.add_child(mi)

static func _ridge(root: Node3D, z: float, base_y: float, amp: float, seed: float, cb: Color, ct: Color, hz: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var P := func(u: float, v: float) -> Vector3:
		var x := lerpf(-160.0, 160.0, u)
		var top := base_y + amp * (0.55 + 0.25 * sin(x * 0.035 + seed) + 0.15 * sin(x * 0.09 + seed * 2.0) + 0.06 * sin(x * 0.23 + seed * 3.0))
		var y := lerpf(base_y - 20.0, top, v)
		var zz := z - 0.004 * x * x * 0.3
		return Vector3(x, y, zz)
	Geo.patch(st, P, 160, 4, {"closed_u": false, "orient": func(u, v, p): return Vector3(0, 0, 1),
		"uvfn": func(u, v, p): return Vector2(u, v)})
	var m := ArrayMesh.new()
	Geo.finish(st, m, mat("FAR", TShaders.FAR, {"base": cb, "top": ct, "hz": hz}), "far")
	var mi := MeshInstance3D.new(); mi.mesh = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)

static func _far(root: Node3D) -> void:
	_ridge(root, -150.0, -6.0, 26.0, 1.0, Color(0.45, 0.58, 0.70), Color(0.62, 0.74, 0.82), 0.55)
	_ridge(root, -95.0, -6.0, 13.0, 4.0, Color(0.36, 0.55, 0.42), Color(0.55, 0.72, 0.50), 0.38)
	_ridge(root, -55.0, -5.0, 5.5, 7.5, Color(0.36, 0.56, 0.30), Color(0.56, 0.74, 0.36), 0.18)

static func _trees(root: Node3D) -> void:
	var c := TChar.new() # just for its material/geometry helpers (not added as a character)
	c.toon("tree", Color(0.20, 0.42, 0.24), Color(0.42, 0.66, 0.30), {"shade": Color(0.55, 0.62, 0.86), "brush": 0.12, "width": 0.0022})
	c.toon("trunk", Color(0.32, 0.22, 0.18), Color(0.48, 0.34, 0.24), {"width": 0.0022})
	var rng := RandomNumberGenerator.new(); rng.seed = 5
	var spots := [Vector3(-7.5, 0, -16), Vector3(-4.6, 0, -19), Vector3(8.5, 0, -14), Vector3(12.0, 0, -22), Vector3(5.0, 0, -26), Vector3(-13, 0, -24)]
	var sts := {"tree": Geo.new_st(false), "trunk": Geo.new_st(false)}
	for sp in spots:
		var g: Vector3 = sp + Vector3(0, hill_h(sp.x, sp.z), 0)
		var s := rng.randf_range(0.8, 1.3)
		var trunk := func(t: float) -> Vector3: return g + Vector3(0, t * 2.2 * s, 0)
		Geo.tube(sts.trunk, trunk, 10, 4, func(v, th): return Vector2(0.18, 0.18) * s * (1.0 - 0.4 * v), {"uv2fn": func(u, v, p): return Vector2(0, v)})
		for k in 5:
			var cc: Vector3 = g + Vector3(rng.randf_range(-1, 1), 2.6 + rng.randf_range(-0.2, 1.0), rng.randf_range(-0.6, 0.6)) * s
			var rr := rng.randf_range(0.9, 1.4) * s
			var P := func(u: float, v: float) -> Vector3:
				var th := u * TAU; var ph := v * PI
				return cc + Vector3(sin(ph) * sin(th), cos(ph) * 0.9, sin(ph) * cos(th)) * rr
			Geo.patch(sts.tree, P, 20, 12, {"closed_u": true, "uv2fn": func(u, v, p): return Vector2(0, 1.0 - v),
				"cfn": func(u, v, p): return Color(0, 0, rng.randf(), 1.0)})
	var m := ArrayMesh.new()
	for k in sts: Geo.finish(sts[k], m, c.mats[k], k)
	var mi := MeshInstance3D.new(); mi.mesh = m
	root.add_child(mi)
	c.free()
