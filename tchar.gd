## Toon character: skeleton from a design table, automatic 2-bone weights,
## per-material SurfaceTools committed into one skinned ArrayMesh, toon
## materials with inverted-hull ink as next_pass, and a procedural idle
## (bounce, breath, blink, head drift, hair/cape springs, wave).
class_name TChar
extends Node3D

var kind := "boy"
var sk: Skeleton3D
var B := {}
var GP := {} # bone global rest positions
var segs := []
var sts := {}
var mats := {}
var tris := {}
var timings := {}
var head: THead
var face: ShaderMaterial
var phase := 0.0
var wave := 0.0 # 0..1 weight, driven by main
var mouth := 0.0
var pose := {}
static var registry := [] # every toon / ink material, for the breakdown stages

# ------------------------------------------------------------- skeleton
func bones(table: Array, seg_list: Array) -> void:
	sk = Skeleton3D.new()
	for row in table:
		var i := sk.add_bone(row[0])
		B[row[0]] = i
		GP[row[0]] = row[2]
		var pp := Vector3.ZERO
		if row[1] != "":
			sk.set_bone_parent(i, B[row[1]])
			pp = GP[row[1]]
		sk.set_bone_rest(i, Transform3D(Basis(), (row[2] as Vector3) - pp))
	sk.reset_bone_poses()
	add_child(sk)
	segs = seg_list

static func seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var h := clampf((p - a).dot(ab) / maxf(ab.dot(ab), 1e-9), 0.0, 1.0)
	return (p - a - ab * h).length()

func wauto(p: Vector3, only := []) -> Array:
	var best := [1e9, 1e9]
	var bi := [0, 0]
	for s in segs:
		if only.size() > 0 and not (s[0] in only): continue
		var d: float = seg_dist(p, s[1], s[2]) * s[3]
		if d < best[0]:
			best[1] = best[0]; bi[1] = bi[0]
			best[0] = d; bi[0] = B[s[0]]
		elif d < best[1]:
			best[1] = d; bi[1] = B[s[0]]
	var w := clampf(0.5 - (best[1] - best[0]) / 0.035, 0.0, 0.5)
	return [bi[0], bi[1], w]

func AUTO() -> Callable:
	return func(u, v, p): return wauto(p)

func ONLY(names: Array) -> Callable:
	return func(u, v, p): return wauto(p, names)

func ARM(s: String) -> Callable: return ONLY(["chest", "upperarm_" + s, "forearm_" + s, "hand_" + s])
func LEG(s: String) -> Callable: return ONLY(["pelvis", "thigh_" + s, "shin_" + s, "foot_" + s])

## torso-only weights (garment bodies must not follow the arms)
func BODY() -> Callable:
	var only := ["pelvis", "spine", "chest", "neck", "thigh_L", "thigh_R"]
	return func(u, v, p): return wauto(p, only)

func rigid(b: String) -> Callable:
	var i: int = B[b]
	return func(u, v, p): return [i, i, 0.0]

# ------------------------------------------------------------- materials
static var _sh := {}
static func shader(name: String, code: String) -> Shader:
	if not _sh.has(name):
		var s := Shader.new(); s.code = code; _sh[name] = s
	return _sh[name]

static func ink_of(c: Color) -> Color:
	return Color(c.r * 0.30 + 0.03, c.g * 0.22 + 0.02, c.b * 0.22 + 0.03)

func _mat(name: String, code: String, params: Dictionary, ink: Color, width := 0.0028) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader(name, code)
	for k in params: m.set_shader_parameter(k, params[k])
	var o := ShaderMaterial.new()
	o.shader = shader("OUTLINE", TShaders.OUTLINE)
	o.set_shader_parameter("ink", ink)
	o.set_shader_parameter("width", width)
	m.next_pass = o
	registry.append(m); registry.append(o)
	return m

## cloth/prop material: gradient bottom col_a -> top col_b
func toon(key: String, a: Color, b: Color, o := {}) -> void:
	var p := {"col_a": a, "col_b": b}
	for k in o:
		if k != "ink" and k != "width" and k != "double": p[k] = o[k]
	var code: String = TShaders.TOON
	var nm := "TOON"
	if o.get("double", false):
		code = code.replace("render_mode cull_back;", "render_mode cull_disabled;").replace("c = mix(c, trim, COLOR.r);", "c = mix(c, trim, COLOR.r);\n\tif (!FRONT_FACING) c *= 0.78;")
		nm = "TOON2"
	mats[key] = _mat(nm, code, p, o.get("ink", ink_of(a)), o.get("width", 0.0028))

func face_mat(key: String, p: Dictionary, ink: Color) -> void:
	face = _mat("FACE", TShaders.FACE, p, ink)
	mats[key] = face

func hair_mat(key: String, p: Dictionary, ink: Color) -> void:
	mats[key] = _mat("HAIR", TShaders.HAIR, p, ink)

func st(key: String) -> SurfaceTool:
	if not sts.has(key): sts[key] = Geo.new_st(true)
	return sts[key]

# ------------------------------------------------------------- geometry helpers
## lathe: prof(v) -> [y, rx, rz, zc]; fold(th, v) -> radial scale; u=0 is front (+z)
func lathe(key: String, prof: Callable, nu: int, nv: int, o := {}) -> void:
	var fold: Callable = o.get("fold", Callable())
	var ya: float = prof.call(0.0)[0]
	var yb: float = prof.call(1.0)[0]
	var trim: Callable = o.get("trim", Callable())
	var seed: float = o.get("seed", 0.0)
	var P := func(u: float, v: float) -> Vector3:
		var r: Array = prof.call(v)
		var th := u * TAU
		var k := 1.0
		if fold.is_valid(): k = fold.call(th, v)
		return Vector3(sin(th) * r[1] * k, r[0], r[3] + cos(th) * r[2] * k) + (o.get("off", Vector3.ZERO) as Vector3)
	Geo.patch(st(key), P, nu, nv, {"closed_u": true, "bfn": o.get("bfn", AUTO()),
		"uv2fn": func(u, v, p): return Vector2(0.0, inverse_lerp(minf(ya, yb), maxf(ya, yb), p.y) if absf(yb - ya) > 1e-5 else 0.5),
		"cfn": func(u, v, p): return Color(trim.call(u, v) if trim.is_valid() else 0.0, 0.0, seed, o.get("ow", 1.0)),
		"orient": o.get("orient", Callable())})

func tube(key: String, pts: Array, rfn: Callable, nu: int, nv: int, o := {}) -> void:
	var curve := func(t: float) -> Vector3: return Geo.crspline(pts, t)
	var ow: float = o.get("ow", 1.0)
	var trim: Callable = o.get("trim", Callable())
	var g: Callable = o.get("g", func(v): return 1.0 - v)
	Geo.tube(st(key), curve, nu, nv, func(v, th): var r = rfn.call(v); return r if r is Vector2 else Vector2(r, r),
		{"bfn": o.get("bfn", AUTO()), "up": o.get("up", Vector3.FORWARD),
		"uv2fn": func(u, v, p): return Vector2(0.0, g.call(v)),
		"cfn": func(u, v, p): return Color(trim.call(u, v) if trim.is_valid() else 0.0, 0.0, o.get("seed", 0.0), ow)})

func blob(key: String, c: Vector3, r: Vector3, o := {}) -> void:
	var P := func(u: float, v: float) -> Vector3:
		var th := u * TAU
		var ph := v * PI
		var q := Vector3(sin(ph) * sin(th) * r.x, cos(ph) * r.y, sin(ph) * cos(th) * r.z)
		if o.has("basis"): q = (o.basis as Basis) * q
		return c + q
	Geo.patch(st(key), P, o.get("nu", 24), o.get("nv", 14), {"closed_u": true, "bfn": o.get("bfn", AUTO()),
		"uv2fn": func(u, v, p): return Vector2(0.0, 1.0 - v),
		"cfn": func(u, v, p): return Color(0.0, 0.0, o.get("seed", 0.0), o.get("ow", 1.0))})

## mitten hand at a wrist; side +1 = L (+x)
func mitten(key: String, w: Vector3, side: float, bone: String, s := 1.0) -> void:
	var c := w + Vector3(0.0, -0.032, 0.006) * s
	blob(key, c, Vector3(0.022, 0.032, 0.026) * s, {"bfn": rigid(bone)})
	blob(key, c + Vector3(-side * 0.006, 0.008, 0.022) * s, Vector3(0.010, 0.016, 0.010) * s, {"bfn": rigid(bone), "nu": 14, "nv": 8,
		"basis": Basis(Vector3.RIGHT, -0.6)})

# ------------------------------------------------------------- commit
func commit() -> void:
	var mesh := ArrayMesh.new()
	for k in sts:
		Geo.tri_count.clear()
		Geo.finish(sts[k], mesh, mats[k], k)
		tris[k] = Geo.tri_count[k]
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	sk.add_child(mi)
	mi.skeleton = NodePath("..")
	mi.skin = sk.create_skin_from_rest_transforms()

func total_tris() -> int:
	var n := 0
	for k in tris: n += tris[k]
	return n

# ------------------------------------------------------------- animation
func rot(n: String, x: float, y := 0.0, z := 0.0) -> void:
	if B.has(n): sk.set_bone_pose_rotation(B[n], Quaternion.from_euler(Vector3(x, y, z)))

func blink_at(t: float) -> float:
	var period := 3.4
	var l := fposmod(t + phase * 1.7, period)
	var b := 1.0 - clampf(absf(l - 0.15) / 0.09, 0.0, 1.0)
	var l2 := fposmod(t + phase * 1.7 + 1.3, period * 2.0)
	b = maxf(b, 1.0 - clampf(absf(l2 - 0.15) / 0.08, 0.0, 1.0))
	return smoothstep(0.0, 1.0, b)

func idle(time: float) -> void:
	var t := time + phase
	var br := sin(t * TAU / 3.0)
	var hd := sin(t * TAU / 5.5 + 1.0)
	var sw := sin(t * TAU / 7.0)
	if face:
		face.set_shader_parameter("blink", blink_at(time))
		face.set_shader_parameter("mouth", mouth)
	if kind == "spirit":
		var bob := sin(t * TAU / 1.9)
		sk.set_bone_pose_position(B.pelvis, GP.pelvis + Vector3(0, 0.025 * bob, 0))
		sk.set_bone_pose_scale(B.head, Vector3(1.0 - 0.025 * bob, 1.0 + 0.04 * bob, 1.0 - 0.025 * bob))
		rot("head", 0.05 * hd, 0.15 * sw, 0.06 * sin(t * TAU / 2.6))
		rot("upperarm_L", 0.0, 0.0, 0.35 + 0.30 * sin(t * TAU / 0.95) * (0.4 + 0.6 * wave))
		rot("upperarm_R", 0.0, 0.0, -0.35 - 0.30 * sin(t * TAU / 0.95 + 0.4) * (0.4 + 0.6 * wave))
		rot("thigh_L", 0.15 * sin(t * TAU / 1.9), 0, 0)
		rot("thigh_R", 0.15 * sin(t * TAU / 1.9 + 1.0), 0, 0)
		rot("hairA", 0.12 * sin((t - 0.3) * TAU / 1.9), 0, 0.18 * sin((t - 0.2) * TAU / 2.6))
		rot("hairB", 0.15 * sin((t - 0.5) * TAU / 1.9), 0, 0.2 * sin((t - 0.4) * TAU / 2.6))
		return
	var bounce := sin(t * TAU / 1.5)
	sk.set_bone_pose_position(B.pelvis, GP.pelvis + Vector3(0.004 * sw, 0.004 * bounce, 0))
	rot("pelvis", 0.0, 0.03 * sw, 0.025 * sw)
	rot("spine", 0.015 * br, 0.0, -0.02 * sw)
	rot("chest", -0.02 * br, -0.02 * sw, -0.015 * sw)
	rot("neck", 0.0, 0.05 * hd, 0.0)
	rot("head", 0.04 * sin(t * TAU / 4.3) - 0.05 * wave, 0.08 * hd, 0.05 * sw + (pose.get("tilt", 0.0) as float))
	for s in ["L", "R"]:
		var sg := 1.0 if s == "L" else -1.0
		rot("thigh_" + s, 0.0, 0.0, sg * 0.03 - 0.02 * sw)
		rot("shin_" + s, 0.0, 0.0, 0.0)
		rot("upperarm_" + s, 0.06 + 0.03 * br + (pose.get("arm_x_" + s, 0.0) as float), 0.0, sg * (0.16 + 0.02 * br) + (pose.get("arm_z_" + s, 0.0) as float))
		rot("forearm_" + s, -0.22 - 0.05 * br + (pose.get("fore_x_" + s, 0.0) as float), 0.0, 0.0)
	# wave (right arm)
	if wave > 0.001:
		var w := wave
		var ua := Quaternion.from_euler(Vector3(0.06 - 0.35 * w, 0.0, lerpf(-0.16, -2.55, w)))
		sk.set_bone_pose_rotation(B.upperarm_R, ua)
		var osc := sin(time * TAU * 1.7)
		sk.set_bone_pose_rotation(B.forearm_R, Quaternion.from_euler(Vector3(-0.22 * (1.0 - w), 0.0, w * (0.55 + 0.42 * osc))))
		sk.set_bone_pose_rotation(B.hand_R, Quaternion.from_euler(Vector3(0.0, -0.4 * w, w * 0.15 * osc)))
	# springs: cape, skirt, hair, hat
	var lag := sin((t - 0.45) * TAU / 7.0)
	var lb := sin((t - 0.3) * TAU / 1.5)
	rot("capeA", 0.05 + 0.03 * sin((t - 0.4) * TAU / 3.0) + 0.02 * lb, 0.0, 0.04 * lag)
	rot("capeB", 0.04 + 0.04 * sin((t - 0.8) * TAU / 3.0) + 0.02 * lb, 0.0, 0.06 * lag)
	rot("skirtF", -0.02 * lb, 0.0, -0.03 * lag)
	rot("skirtB", 0.03 * lb, 0.0, -0.03 * lag)
	rot("hairA", 0.04 * sin((t - 0.35) * TAU / 3.0) + 0.02 * lb, 0.0, -0.05 * lag)
	rot("hairB", 0.05 * sin((t - 0.6) * TAU / 3.0) + 0.03 * lb, 0.0, -0.07 * lag)
	rot("ahoge", 0.12 * sin((t - 0.2) * TAU / 1.5), 0.0, 0.15 * sin((t - 0.3) * TAU / 2.2))
	rot("hat", 0.02 * sin((t - 0.25) * TAU / 1.5), 0.0, 0.015 * lag)
