## The three original designs: Pip (boy adventurer, cape + star wand),
## Wren (girl archer, big traveller hat + bow) and Mochi (round leaf spirit).
class_name Designs
extends RefCounted

static func human_table(J: Dictionary, extra: Array) -> Array:
	var t := [["pelvis", "", J.pelvis], ["spine", "pelvis", J.spine], ["chest", "spine", J.chest],
		["neck", "chest", J.neck], ["head", "neck", J.head]]
	for s in ["L", "R"]:
		t.append(["upperarm_" + s, "chest", J["shoulder_" + s]])
		t.append(["forearm_" + s, "upperarm_" + s, J["elbow_" + s]])
		t.append(["hand_" + s, "forearm_" + s, J["wrist_" + s]])
		t.append(["thigh_" + s, "pelvis", J["hip_" + s]])
		t.append(["shin_" + s, "thigh_" + s, J["knee_" + s]])
		t.append(["foot_" + s, "shin_" + s, J["ankle_" + s]])
	t.append_array(extra)
	return t

static func human_segs(J: Dictionary, hc: Vector3) -> Array:
	var s := [["pelvis", J.pelvis + Vector3(0, -0.06, 0), J.spine, 1.0], ["spine", J.spine, J.chest, 1.0],
		["chest", J.chest, J.neck, 1.0], ["neck", J.neck, J.head, 1.3], ["head", J.head, hc, 0.7]]
	for sd in ["L", "R"]:
		s.append(["upperarm_" + sd, J["shoulder_" + sd], J["elbow_" + sd], 1.2])
		s.append(["forearm_" + sd, J["elbow_" + sd], J["wrist_" + sd], 1.0])
		s.append(["hand_" + sd, J["wrist_" + sd], (J["wrist_" + sd] as Vector3) + Vector3(0, -0.06, 0), 1.0])
		s.append(["thigh_" + sd, J["hip_" + sd], J["knee_" + sd], 1.5])
		s.append(["shin_" + sd, J["knee_" + sd], J["ankle_" + sd], 1.0])
		s.append(["foot_" + sd, J["ankle_" + sd], (J["ankle_" + sd] as Vector3) + Vector3(0, -0.04, 0.10), 1.0])
	return s

static func mirror(J: Dictionary) -> Dictionary:
	for k in J.keys():
		if (k as String).ends_with("_L"):
			var v: Vector3 = J[k]
			J[(k as String).replace("_L", "_R")] = Vector3(-v.x, v.y, v.z)
	return J

static func skin_params(c: TChar, skin: Color, skin_b: Color) -> Dictionary:
	return {"col_a": skin_b, "col_b": skin, "shade": Color(0.88, 0.66, 0.66), "mid": Color(0.97, 0.88, 0.86), "brush": 0.03}

## common head + face + ears + neck
static func head_parts(c: TChar, J: Dictionary, skin: Color, skin_b: Color, ears := true) -> void:
	c.head.build(c.st("face"), 110, 84, c.B.head)
	if ears:
		for s in [-1.0, 1.0]:
			c.blob("skin", c.head.world(Vector3(s * 0.95, -0.16, -0.04)), Vector3(0.10, 0.17, 0.12) * c.head.R, {"bfn": c.rigid("head"), "nu": 16, "nv": 10})
	c.tube("skin", [J.neck + Vector3(0, -0.03, 0), J.neck, J.head + Vector3(0, 0.03, 0.0), c.head.c + Vector3(0, -0.3, -0.1) * c.head.R], func(v): return 0.035, 14, 6)

# ================================================================ Pip
static func boy(c: TChar) -> void:
	var J := mirror({
		"pelvis": Vector3(0, 0.46, 0), "spine": Vector3(0, 0.54, 0), "chest": Vector3(0, 0.64, 0),
		"neck": Vector3(0, 0.745, -0.005), "head": Vector3(0, 0.79, 0),
		"shoulder_L": Vector3(0.088, 0.712, -0.004), "elbow_L": Vector3(0.122, 0.594, -0.004), "wrist_L": Vector3(0.136, 0.482, 0.012),
		"hip_L": Vector3(0.047, 0.44, 0), "knee_L": Vector3(0.051, 0.262, 0.008), "ankle_L": Vector3(0.052, 0.078, 0)})
	var hc := Vector3(0, 0.905, 0.012)
	c.head = THead.new("kid", 0.126, hc, {"jaw": 1.0, "chin": 1.0})
	c.bones(human_table(J, [["capeA", "chest", Vector3(0, 0.72, -0.07)], ["capeB", "capeA", Vector3(0, 0.52, -0.12)],
		["hairA", "head", hc + Vector3(0, 0.0, -0.1)], ["ahoge", "head", hc + Vector3(0, 0.12, 0)]]), human_segs(J, hc))
	var skin := Color(1.0, 0.87, 0.75); var skin_b := Color(0.98, 0.80, 0.70)
	c.face_mat("face", {"skin": skin, "skin_b": skin_b, "iris_a": Color(0.10, 0.12, 0.20), "iris_b": Color(0.32, 0.52, 0.72),
		"brow_col": Color(0.24, 0.16, 0.13), "shade": Color(0.88, 0.66, 0.66), "mid": Color(0.97, 0.88, 0.86)}, Color(0.30, 0.15, 0.11))
	c.toon("skin", skin_b, skin, {"shade": Color(0.88, 0.66, 0.66), "mid": Color(0.97, 0.88, 0.86), "brush": 0.02, "ink": Color(0.30, 0.15, 0.11)})
	c.toon("tunic", Color(0.20, 0.42, 0.36), Color(0.40, 0.66, 0.50), {"trim": Color(0.96, 0.86, 0.58), "shade": Color(0.55, 0.55, 0.78)})
	c.toon("leg", Color(0.40, 0.30, 0.26), Color(0.52, 0.40, 0.33), {"shade": Color(0.62, 0.55, 0.75)})
	c.toon("leather", Color(0.36, 0.22, 0.14), Color(0.58, 0.38, 0.22), {"trim": Color(0.82, 0.62, 0.36), "shade": Color(0.66, 0.52, 0.66)})
	c.toon("cape", Color(0.62, 0.16, 0.16), Color(0.88, 0.30, 0.24), {"double": true, "trim": Color(0.98, 0.82, 0.45), "shade": Color(0.62, 0.48, 0.70)})
	c.toon("gold", Color(0.86, 0.62, 0.20), Color(1.0, 0.86, 0.42), {"shade": Color(0.78, 0.58, 0.55), "brush": 0.0, "width": 0.0022})
	c.toon("star", Color(1.0, 0.82, 0.30), Color(1.0, 0.96, 0.70), {"shade": Color(0.92, 0.72, 0.55), "emit": 0.35, "brush": 0.0, "width": 0.0022})
	c.toon("wood", Color(0.42, 0.26, 0.16), Color(0.58, 0.40, 0.24), {"width": 0.0022})
	c.hair_mat("hair", {"hair": Color(0.36, 0.22, 0.16), "hair_dark": Color(0.22, 0.13, 0.10), "hi_col": Color(0.42, 0.32, 0.24), "hl_y": 0.66,
		"shade": Color(0.58, 0.50, 0.72)}, Color(0.12, 0.07, 0.06))
	head_parts(c, J, skin, skin_b)
	# tunic: one lathe from neckline to a flared, softly folded hem
	var tun := func(v: float) -> Array:
		var y := lerpf(0.758, 0.325, v)
		var rx := Geo.table([[0.0, 0.040], [0.06, 0.072], [0.15, 0.093], [0.40, 0.086], [0.6, 0.089], [0.8, 0.106], [1.0, 0.128]], v)
		return [y, rx, rx * 0.86, 0.0]
	c.lathe("tunic", tun, 64, 30, {"bfn": c.BODY(), "fold": func(th, v): return 1.0 + 0.045 * sin(th * 5.0 + 0.5) * smoothstep(0.55, 1.0, v),
		"trim": func(u, v): return 1.0 if v > 0.92 or v < 0.035 else 0.0})
	# belt + buckle + pouch
	var bl := func(t: float) -> Vector3: return Vector3(sin(t * TAU) * 0.094, 0.505 - 0.006 * cos(t * TAU), cos(t * TAU) * 0.082)
	Geo.tube(c.st("leather"), bl, 10, 40, func(v, th): return Vector2(0.006, 0.016), {"bfn": c.BODY(), "up": Vector3.UP,
		"uv2fn": func(u, v, p): return Vector2(0, 0.6), "cfn": func(u, v, p): return Color(0, 0, 0, 0.8)})
	c.blob("gold", Vector3(0, 0.50, 0.086), Vector3(0.020, 0.017, 0.007), {"bfn": c.rigid("pelvis")})
	c.blob("leather", Vector3(-0.085, 0.475, 0.035), Vector3(0.024, 0.030, 0.018), {"bfn": c.rigid("pelvis")})
	# sleeves (tunic) and forearms, mitten hands
	for s in ["L", "R"]:
		var sg := 1.0 if s == "L" else -1.0
		var sh: Vector3 = J["shoulder_" + s]; var el: Vector3 = J["elbow_" + s]; var wr: Vector3 = J["wrist_" + s]
		c.tube("tunic", [sh + Vector3(-sg * 0.02, 0.025, 0), sh + Vector3(0, 0.006, 0), el, el.lerp(wr, 0.45)],
			func(v): return Geo.table([[0.0, 0.034], [0.2, 0.040], [0.7, 0.036], [1.0, 0.037]], v), 16, 14,
			{"trim": func(u, v): return 1.0 if v > 0.86 else 0.0, "bfn": c.ARM(s)})
		c.tube("skin", [el, el.lerp(wr, 0.5), wr, wr + Vector3(0, -0.02, 0)], func(v): return lerpf(0.025, 0.021, v), 12, 8, {"bfn": c.ARM(s)})
		c.mitten("skin", wr, sg, "hand_" + s)
		# legs + boots with a folded cuff
		var hp: Vector3 = J["hip_" + s]; var kn: Vector3 = J["knee_" + s]; var an: Vector3 = J["ankle_" + s]
		c.tube("leg", [hp + Vector3(0, 0.03, 0), hp, kn, an], func(v): return lerpf(0.040, 0.029, v), 14, 14, {"bfn": c.LEG(s)})
		c.tube("leather", [an + Vector3(0, 0.125, 0), an + Vector3(0, 0.03, 0), an + Vector3(0, -0.035, 0.045), an + Vector3(0, -0.05, 0.118)],
			func(v): return Vector2(Geo.table([[0.0, 0.040], [0.4, 0.039], [0.75, 0.040], [1.0, 0.033]], v), Geo.table([[0.0, 0.040], [0.5, 0.038], [0.8, 0.028], [1.0, 0.024]], v)) * sqrt(clampf((1.0 - v) / 0.12, 0.0, 1.0)) + Vector2(0.002, 0.002),
			16, 18, {"up": Vector3.UP, "bfn": c.LEG(s)})
		var cf := func(t: float) -> Vector3: return an + Vector3(sin(t * TAU) * 0.044, 0.20, cos(t * TAU) * 0.044)
		Geo.tube(c.st("leather"), cf, 8, 24, func(v, th): return Vector2(0.012, 0.009), {"bfn": c.LEG(s), "up": Vector3.UP,
			"uv2fn": func(u, v, p): return Vector2(0, 1.0), "cfn": func(u, v, p): return Color(1, 0, 0, 0.8)})
	# cape: hangs from a collar around the shoulders, a few big soft folds
	var CP := func(u: float, v: float) -> Vector3:
		var a := lerpf(-1.95, 1.95, u)
		var r := lerpf(0.082, 0.175, pow(v, 0.8))
		var y := lerpf(0.752, 0.30, v)
		var z := -cos(a) * r * lerpf(0.95, 0.85, v) - 0.055 * v - 0.010
		var fold := 0.016 * sin(u * TAU * 2.5 + 0.6) * smoothstep(0.1, 1.0, v)
		var p := Vector3(sin(a) * r, y - 0.012 * v * sin(u * TAU * 2.5) , z)
		p += Vector3(sin(a), 0, -cos(a)) * fold
		return p
	var capeA: int = c.B.capeA; var capeB: int = c.B.capeB; var chest: int = c.B.chest
	Geo.patch(c.st("cape"), CP, 40, 26, {"closed_u": false,
		"orient": func(u, v, p): return Vector3(p.x, 0, p.z + 0.02),
		"bfn": func(u, v, p): return [chest, capeA, v / 0.25] if v < 0.25 else [capeA, capeB, (v - 0.25) / 0.75],
		"uv2fn": func(u, v, p): return Vector2(0, 1.0 - v),
		"cfn": func(u, v, p): return Color(1.0 if v > 0.94 else 0.0, 0, 0.3, 1.0)})
	var col := func(t: float) -> Vector3:
		var a := lerpf(-2.0, 2.0, t)
		return Vector3(sin(a) * 0.080, 0.758 + 0.004 * cos(a), -cos(a) * 0.072 + 0.004)
	Geo.tube(c.st("cape"), col, 12, 30, func(v, th): return Vector2(0.016, 0.013) * (0.6 + 0.4 * sin(v * PI)), {"bfn": c.rigid("chest"), "up": Vector3.UP,
		"uv2fn": func(u, v, p): return Vector2(0, 1.0), "cfn": func(u, v, p): return Color(0, 0, 0.5, 0.9)})
	for s in [-1.0, 1.0]:
		c.blob("gold", Vector3(s * 0.056, 0.742, 0.058), Vector3(0.013, 0.013, 0.006), {"bfn": c.rigid("chest"), "nu": 16, "nv": 10})
	# star wand in the left hand
	var hw: Vector3 = J.wrist_L + Vector3(0.0, -0.034, 0.012)
	var wd := Vector3(0.05, -0.30, 1.0).normalized()
	c.tube("wood", [hw - wd * 0.06, hw, hw + wd * 0.12, hw + wd * 0.22], func(v): return lerpf(0.0085, 0.0062, v), 10, 10, {"bfn": c.rigid("hand_L"), "ow": 0.8})
	var tip: Vector3 = hw + wd * 0.235
	var SP := func(u: float, v: float) -> Vector3:
		var th := u * TAU
		var rr := 0.034 * (0.48 + 0.52 * pow(absf(cos(2.5 * th)), 2.2))
		var sv := sin(v * PI)
		return tip + Basis(Vector3.RIGHT, -0.3) * Vector3(sin(th) * rr * sv, cos(th) * rr * sv, -cos(v * PI) * 0.010)
	Geo.patch(c.st("star"), SP, 60, 10, {"closed_u": true, "bfn": c.rigid("hand_L"),
		"uv2fn": func(u, v, p): return Vector2(0, 1.0 - v), "cfn": func(u, v, p): return Color(0, 0, 0, 0.8)})
	# hair: cap + messy chunky locks + an ahoge
	var hr := THair.new(c, 7)
	var hl := func(az: float) -> float:
		var a := absf(wrapf(az, -PI, PI))
		return Geo.table([[0.0, 1.05], [0.9, 1.25], [1.45, 1.6], [2.2, 2.0], [PI, 2.25]], a)
	hr.cap("hair", 0.055, hl, "head")
	var hA := func(u, v, p): return [c.B.head, c.B.hairA, smoothstep(0.2, 1.0, v) * 0.8]
	for i in 9:
		var az := lerpf(-0.95, 0.95, i / 8.0) + hr.rng.randf_range(-0.04, 0.04)
		hr.lock("hair", az, 0.30, 0.98 + 0.12 * absf(az) + hr.rng.randf_range(-0.08, 0.1), {"w": 0.30, "thick": 0.11, "grav": 0.15,
			"curl": Vector3(signf(az + 0.01) * 0.25, 0.0, 0.15)})
	# forehead fringe: pointed clumps hanging over the brow (breaks the helmet hairline)
	for i in 7:
		var az := lerpf(-0.78, 0.78, i / 6.0) + hr.rng.randf_range(-0.03, 0.03)
		var zig := 1.0 if i % 2 == 0 else -1.0
		hr.lock("hair", az, 0.90, 0.62 + 0.10 * absf(az) + hr.rng.randf_range(-0.05, 0.08), {"w": 0.32, "thick": 0.13, "grav": 0.2,
			"curl": Vector3(zig * 0.35 + az * 0.3, 0.0, 0.12)})
	for s in [-1.0, 1.0]:
		for k in 3:
			var az: float = s * (1.0 + 0.32 * k)
			hr.lock("hair", az, 0.55, 1.0 + 0.08 * k, {"w": 0.30, "thick": 0.11, "grav": 0.35, "curl": Vector3(s * 0.45, 0.2, -0.1)})
	for k in 6:
		var az := PI + lerpf(-1.1, 1.1, k / 5.0)
		hr.lock("hair", az, 0.45, 1.05 + hr.rng.randf_range(0.0, 0.15), {"w": 0.34, "thick": 0.12, "grav": 0.4,
			"curl": Vector3(sin(az) * 0.6, 0.5, -0.6), "bfn": hA})
	for k in 5:
		var az := PI + lerpf(-1.4, 1.4, k / 4.0)
		hr.lock("hair", az, 0.10, 1.25, {"w": 0.36, "thick": 0.12, "grav": 0.25, "curl": Vector3(sin(az) * 0.3, 0.6, -0.5)})
	var ah: int = c.B.ahoge
	hr.lock("hair", 0.3, 0.02, 0.62, {"dir0": Vector3(0.1, 1.0, -0.4), "w": 0.13, "thick": 0.06, "grav": 0.0,
		"curl": Vector3(0.0, -1.6, 1.4), "off": 0.03, "bfn": func(u, v, p): return [ah, ah, 0.0]})

# ================================================================ Wren
static func girl(c: TChar) -> void:
	var J := mirror({
		"pelvis": Vector3(0, 0.50, 0), "spine": Vector3(0, 0.58, 0), "chest": Vector3(0, 0.69, 0),
		"neck": Vector3(0, 0.80, -0.005), "head": Vector3(0, 0.845, 0),
		"shoulder_L": Vector3(0.083, 0.768, -0.004), "elbow_L": Vector3(0.114, 0.642, -0.006), "wrist_L": Vector3(0.126, 0.524, 0.016),
		"hip_L": Vector3(0.046, 0.48, 0), "knee_L": Vector3(0.049, 0.282, 0.008), "ankle_L": Vector3(0.05, 0.078, 0)})
	var hc := Vector3(0, 0.962, 0.012)
	c.head = THead.new("kid", 0.122, hc, {"jaw": 0.96, "chin": 0.92, "long": 1.03})
	c.bones(human_table(J, [["skirtF", "pelvis", Vector3(0, 0.50, 0.06)], ["skirtB", "pelvis", Vector3(0, 0.50, -0.06)],
		["hat", "head", hc + Vector3(0, 0.06, 0)], ["hairA", "head", hc + Vector3(0, -0.04, -0.08)], ["hairB", "hairA", hc + Vector3(0, -0.16, -0.10)]]), human_segs(J, hc))
	var skin := Color(1.0, 0.88, 0.78); var skin_b := Color(0.99, 0.81, 0.72)
	c.face_mat("face", {"skin": skin, "skin_b": skin_b, "iris_a": Color(0.16, 0.10, 0.08), "iris_b": Color(0.58, 0.36, 0.18),
		"brow_col": Color(0.42, 0.20, 0.12), "eye_w": 0.205, "eye_h": 0.27, "mouth_w": 0.075,
		"shade": Color(0.88, 0.66, 0.66), "mid": Color(0.97, 0.88, 0.86), "blush_col": Color(1.0, 0.52, 0.50)}, Color(0.32, 0.15, 0.11))
	c.toon("skin", skin_b, skin, {"shade": Color(0.88, 0.66, 0.66), "mid": Color(0.97, 0.88, 0.86), "brush": 0.02, "ink": Color(0.32, 0.15, 0.11)})
	c.toon("dress", Color(0.56, 0.20, 0.22), Color(0.86, 0.38, 0.30), {"trim": Color(0.98, 0.88, 0.62), "shade": Color(0.62, 0.48, 0.72)})
	c.toon("apron", Color(0.86, 0.84, 0.74), Color(0.99, 0.97, 0.90), {"double": true, "trim": Color(0.55, 0.70, 0.78), "shade": Color(0.70, 0.70, 0.86)})
	c.toon("blouse", Color(0.86, 0.86, 0.80), Color(1.0, 0.98, 0.93), {"trim": Color(0.55, 0.70, 0.78), "shade": Color(0.70, 0.70, 0.86)})
	c.toon("leg", Color(0.24, 0.24, 0.34), Color(0.34, 0.34, 0.46), {"shade": Color(0.62, 0.58, 0.80)})
	c.toon("leather", Color(0.36, 0.22, 0.14), Color(0.56, 0.36, 0.22), {"trim": Color(0.82, 0.62, 0.36), "shade": Color(0.66, 0.52, 0.66)})
	c.toon("hat", Color(0.68, 0.52, 0.30), Color(0.92, 0.78, 0.48), {"double": true, "trim": Color(0.24, 0.52, 0.56), "shade": Color(0.68, 0.56, 0.68)})
	c.toon("ribbon", Color(0.18, 0.44, 0.50), Color(0.30, 0.62, 0.66), {"shade": Color(0.55, 0.55, 0.80)})
	c.toon("feather", Color(0.86, 0.88, 0.92), Color(1.0, 1.0, 1.0), {"double": true, "trim": Color(0.30, 0.62, 0.66), "shade": Color(0.70, 0.72, 0.88), "width": 0.002})
	c.toon("wood", Color(0.46, 0.27, 0.15), Color(0.66, 0.44, 0.24), {"trim": Color(0.30, 0.55, 0.60), "width": 0.0022})
	c.toon("string", Color(0.92, 0.90, 0.84), Color(0.98, 0.96, 0.90), {"width": 0.0012})
	c.hair_mat("hair", {"hair": Color(0.80, 0.42, 0.22), "hair_dark": Color(0.58, 0.26, 0.15), "hi_col": Color(0.55, 0.42, 0.28), "hl_y": 0.36,
		"shade": Color(0.66, 0.50, 0.66)}, Color(0.30, 0.12, 0.07))
	head_parts(c, J, skin, skin_b)
	# dress: bodice + bell skirt in one lathe, folds grow toward the hem
	var dr := func(v: float) -> Array:
		var y := lerpf(0.815, 0.315, v)
		var rx := Geo.table([[0.0, 0.040], [0.06, 0.068], [0.14, 0.085], [0.30, 0.078], [0.40, 0.072], [0.46, 0.086], [0.65, 0.140], [1.0, 0.195]], v)
		return [y, rx, rx * Geo.table([[0.0, 0.86], [0.45, 0.86], [1.0, 0.92]], v), 0.0]
	var skF: int = c.B.skirtF; var skB: int = c.B.skirtB; var pel: int = c.B.pelvis
	var au := c.BODY()
	c.lathe("dress", dr, 72, 36, {"fold": func(th, v): return 1.0 + 0.06 * sin(th * 6.0 + 0.3) * smoothstep(0.45, 1.0, v),
		"trim": func(u, v): return 1.0 if (v > 0.93 and v < 0.975) or v < 0.03 else 0.0,
		"bfn": func(u, v, p): return au.call(u, v, p) if v < 0.44 else [pel, skF if cos(u * TAU) > 0.0 else skB, smoothstep(0.44, 1.0, v) * 0.9]})
	# apron
	var AP := func(u: float, v: float) -> Vector3:
		var th := lerpf(-0.95, 0.95, u)
		var r: Array = dr.call(lerpf(0.42, 0.88, v))
		var k := 1.0 + 0.06 * sin(th * 6.0 + 0.3) * smoothstep(0.45, 1.0, lerpf(0.42, 0.88, v)) + 0.035
		return Vector3(sin(th) * r[1] * k, r[0], cos(th) * r[2] * k + 0.002)
	Geo.patch(c.st("apron"), AP, 30, 22, {"closed_u": false, "orient": func(u, v, p): return Vector3(p.x, 0, p.z),
		"bfn": func(u, v, p): return [pel, skF, v * 0.8],
		"uv2fn": func(u, v, p): return Vector2(0, 1.0 - v),
		"cfn": func(u, v, p): return Color(1.0 if v > 0.9 else 0.0, 0, 0.6, 0.9)})
	# blouse collar + puff sleeves
	var cl := func(t: float) -> Vector3: return Vector3(sin(t * TAU) * 0.048, 0.808 - 0.012 * (1.0 + cos(t * TAU)) * 0.5, cos(t * TAU) * 0.044)
	Geo.tube(c.st("blouse"), cl, 10, 36, func(v, th): return Vector2(0.010, 0.014), {"bfn": c.rigid("chest"), "up": Vector3.UP,
		"uv2fn": func(u, v, p): return Vector2(0, 1.0), "cfn": func(u, v, p): return Color(0, 0, 0, 0.8)})
	for s in ["L", "R"]:
		var sg := 1.0 if s == "L" else -1.0
		var sh: Vector3 = J["shoulder_" + s]; var el: Vector3 = J["elbow_" + s]; var wr: Vector3 = J["wrist_" + s]
		c.tube("blouse", [sh + Vector3(-sg * 0.02, 0.02, 0), sh + Vector3(0, 0.0, 0), sh.lerp(el, 0.45), sh.lerp(el, 0.6)],
			func(v): return 0.030 + 0.020 * sin(minf(v * 1.1, 1.0) * PI), 16, 12, {"trim": func(u, v): return 1.0 if v > 0.82 else 0.0, "bfn": c.ARM(s)})
		c.tube("skin", [sh, sh.lerp(el, 0.5), el, wr, wr + Vector3(0, -0.02, 0)], func(v): return lerpf(0.024, 0.020, v), 12, 14, {"bfn": c.ARM(s)})
		c.mitten("skin", wr, sg, "hand_" + s, 0.95)
		var hp: Vector3 = J["hip_" + s]; var kn: Vector3 = J["knee_" + s]; var an: Vector3 = J["ankle_" + s]
		c.tube("leg", [hp + Vector3(0, 0.03, 0), hp, kn, an], func(v): return lerpf(0.037, 0.026, v), 14, 14, {"bfn": c.LEG(s)})
		c.tube("leather", [an + Vector3(0, 0.07, 0), an + Vector3(0, 0.02, 0), an + Vector3(0, -0.035, 0.045), an + Vector3(0, -0.048, 0.105)],
			func(v): return Vector2(Geo.table([[0.0, 0.034], [0.5, 0.035], [1.0, 0.030]], v), Geo.table([[0.0, 0.034], [0.6, 0.032], [1.0, 0.022]], v)) * sqrt(clampf((1.0 - v) / 0.14, 0.0, 1.0)) + Vector2(0.002, 0.002),
			16, 16, {"up": Vector3.UP, "bfn": c.LEG(s)})
	# big traveller hat: wide drooping brim (double-sided) + soft crown + ribbon + feather
	var hb := c.head.world(Vector3(0, 0.40, -0.04))
	var tilt := Basis(Vector3.RIGHT, -0.16) * Basis(Vector3.FORWARD, 0.10)
	var BR := func(u: float, v: float) -> Vector3:
		var th := u * TAU
		var r := lerpf(1.0, 2.25, v) * c.head.R
		var y := -0.05 * pow(v, 1.6) * c.head.R * 6.0 * (0.55 + 0.45 * cos(th - 0.3)) + 0.012 * sin(th * 5.0 + 1.0) * v
		return hb + tilt * Vector3(sin(th) * r, y, cos(th) * r)
	var hatb: int = c.B.hat
	Geo.patch(c.st("hat"), BR, 72, 10, {"closed_u": true, "orient": func(u, v, p): return tilt * Vector3.UP,
		"bfn": func(u, v, p): return [hatb, hatb, 0.0], "uv2fn": func(u, v, p): return Vector2(0, 1.0 - v),
		"cfn": func(u, v, p): return Color(0, 0, 0.7, 1.0)})
	var CR := func(v: float) -> Array:
		var y := lerpf(-0.02, 1.0, v) * c.head.R
		var rx := c.head.R * Geo.table([[0.0, 1.16], [0.5, 1.10], [0.8, 0.88], [0.95, 0.50], [1.0, 0.0]], v)
		return [y, rx, rx, 0.0]
	var crown := func(u: float, v: float) -> Vector3:
		var r: Array = CR.call(v)
		var th := u * TAU
		var dent := 1.0 - 0.06 * exp(-pow((v - 0.95) / 0.1, 2.0)) * (0.5 + 0.5 * cos(th))
		return hb + tilt * Vector3(sin(th) * r[1] * dent, r[0], cos(th) * r[2] * dent)
	Geo.patch(c.st("hat"), crown, 48, 16, {"closed_u": true, "bfn": func(u, v, p): return [hatb, hatb, 0.0],
		"uv2fn": func(u, v, p): return Vector2(0, v), "cfn": func(u, v, p): return Color(0, 0, 0.2, 1.0)})
	var rb := func(t: float) -> Vector3: return hb + tilt * Vector3(sin(t * TAU) * c.head.R * 1.15, 0.10 * c.head.R, cos(t * TAU) * c.head.R * 1.15)
	Geo.tube(c.st("ribbon"), rb, 8, 40, func(v, th): return Vector2(0.006, 0.014), {"bfn": func(u, v, p): return [hatb, hatb, 0.0], "up": tilt * Vector3.UP,
		"uv2fn": func(u, v, p): return Vector2(0, 0.6), "cfn": func(u, v, p): return Color(0, 0, 0, 0.8)})
	var fa := hb + tilt * Vector3(c.head.R * 1.12, 0.12 * c.head.R, -0.2 * c.head.R)
	var FP := func(u: float, v: float) -> Vector3:
		var along := fa + tilt * Vector3(0.03 * v, 0.16 * v - 0.03 * v * v, -0.12 * v)
		var wdt := 0.022 * sin(clampf(v, 0.0, 1.0) * PI) * (1.0 - 0.4 * v)
		return along + tilt * Vector3(0.6, 0.0, 0.8).normalized() * (u - 0.5) * 2.0 * wdt
	Geo.patch(c.st("feather"), FP, 4, 14, {"closed_u": false, "orient": func(u, v, p): return tilt * Vector3(0.8, 0.0, -0.6),
		"bfn": func(u, v, p): return [hatb, hatb, 0.0], "uv2fn": func(u, v, p): return Vector2(0, v),
		"cfn": func(u, v, p): return Color(1.0 if v > 0.7 else 0.0, 0, 0, 0.8)})
	# bow in the left hand
	var gp: Vector3 = J.wrist_L + Vector3(0.0, -0.034, 0.014)
	var bpts := []
	for i in 9:
		var t := i / 8.0
		var y := lerpf(0.30, -0.30, t)
		bpts.append(gp + Vector3(0.012 * sin(t * PI), y, 0.075 * sin(t * PI) - 0.03 * pow(absf(t - 0.5) * 2.0, 4.0) - 0.0))
	c.tube("wood", bpts, func(v): return 0.0075 * (1.0 - 0.45 * absf(v - 0.5) * 2.0) + (0.004 if absf(v - 0.5) < 0.07 else 0.0), 10, 40,
		{"bfn": c.rigid("hand_L"), "ow": 0.8, "trim": func(u, v): return 1.0 if absf(v - 0.5) < 0.07 else 0.0})
	var e0: Vector3 = bpts[0]; var e1: Vector3 = bpts[8]
	c.tube("string", [e0, e0.lerp(e1, 0.5), e1], func(v): return 0.0018, 6, 4, {"bfn": c.rigid("hand_L"), "ow": 0.5})
	# hair: cap, blunt-ish bangs, cheek locks, long back locks
	var hr := THair.new(c, 11)
	var hl := func(az: float) -> float:
		var a := absf(wrapf(az, -PI, PI))
		return Geo.table([[0.0, 0.95], [0.9, 1.15], [1.45, 1.6], [2.2, 2.0], [PI, 2.25]], a)
	hr.cap("hair", 0.055, hl, "head")
	for i in 6:
		var az := lerpf(-0.8, 0.8, i / 5.0)
		hr.lock("hair", az, 0.92, 0.72 + 0.10 * absf(az), {"w": 0.36, "thick": 0.15, "grav": 0.2, "curl": Vector3(-az * 0.2, 0.0, 0.1)})
	for s in [-1.0, 1.0]:
		for k in 2:
			var az: float = s * (1.05 + 0.25 * k)
			hr.lock("hair", az, 0.85, 1.45 - 0.15 * k, {"w": 0.46, "thick": 0.20, "grav": 0.7, "curl": Vector3(-s * 0.3, 0.0, 0.35)})
	var hA: int = c.B.hairA; var hB: int = c.B.hairB; var hd: int = c.B.head
	for k in 9:
		var az := PI + lerpf(-1.3, 1.3, k / 8.0)
		hr.lock("hair", az, 0.80, 3.0 + hr.rng.randf_range(-0.15, 0.2), {"w": 0.52, "thick": 0.22, "grav": 0.9,
			"curl": Vector3(sin(az) * 0.15, 0.0, -0.35), "bias": Vector3(0, 0, -0.35), "off": 0.08,
			"bfn": func(u, v, p): return [hd, hA, smoothstep(0.15, 0.5, v)] if v < 0.5 else [hA, hB, smoothstep(0.5, 1.0, v)]})

# ================================================================ Mochi
static func spirit(c: TChar) -> void:
	var R := 0.14
	var hc := Vector3(0, 0, 0)
	c.head = THead.new("spirit", R, hc)
	c.bones([["pelvis", "", Vector3(0, 0, 0)], ["head", "pelvis", Vector3(0, -0.10, 0)],
		["upperarm_L", "head", Vector3(0.88 * R, -0.28 * R, 0.10 * R)], ["upperarm_R", "head", Vector3(-0.88 * R, -0.28 * R, 0.10 * R)],
		["thigh_L", "head", Vector3(0.42 * R, -0.80 * R, 0.15 * R)], ["thigh_R", "head", Vector3(-0.42 * R, -0.80 * R, 0.15 * R)],
		["hairA", "head", Vector3(0, 0.95 * R, -0.02 * R)], ["hairB", "hairA", Vector3(0, 1.25 * R, 0.0)]], [])
	var body := Color(0.94, 0.99, 0.92); var body_b := Color(0.74, 0.90, 0.84)
	c.face_mat("face", {"skin": body, "skin_b": body_b, "iris_a": Color(0.08, 0.10, 0.14), "iris_b": Color(0.20, 0.34, 0.40),
		"brow_col": body_b, "eye_x": 0.38, "eye_y": -0.02, "eye_w": 0.18, "eye_h": 0.22, "brow_y": 0.4, "mouth_y": -0.34, "mouth_w": 0.06,
		"nose_y": -9.0, "lashes": 0.6, "blush_col": Color(1.0, 0.62, 0.62),
		"shade": Color(0.66, 0.74, 0.88), "mid": Color(0.88, 0.94, 0.96)}, Color(0.12, 0.25, 0.26))
	c.toon("body", body_b, body, {"shade": Color(0.66, 0.74, 0.88), "mid": Color(0.88, 0.94, 0.96), "brush": 0.03, "ink": Color(0.12, 0.25, 0.26)})
	c.toon("leaf", Color(0.30, 0.56, 0.26), Color(0.56, 0.80, 0.34), {"double": true, "trim": Color(0.72, 0.90, 0.50), "shade": Color(0.55, 0.62, 0.80)})
	c.head.build(c.st("face"), 110, 84, c.B.head)
	var hd: int = c.B.head
	for s in ["L", "R"]:
		var sg := 1.0 if s == "L" else -1.0
		var b: int = c.B["upperarm_" + s]
		c.blob("body", Vector3(sg * 1.02 * R, -0.42 * R, 0.10 * R), Vector3(0.15, 0.24, 0.15) * R, {"bfn": func(u, v, p): return [b, b, 0.0],
			"basis": Basis(Vector3.FORWARD, sg * 0.5), "nu": 16, "nv": 10})
		var f: int = c.B["thigh_" + s]
		c.blob("body", Vector3(sg * 0.42 * R, -0.95 * R, 0.22 * R), Vector3(0.20, 0.13, 0.24) * R, {"bfn": func(u, v, p): return [f, f, 0.0], "nu": 16, "nv": 10})
	# leaf sprout: stem + two leaves
	var hA: int = c.B.hairA; var hB: int = c.B.hairB
	c.tube("leaf", [Vector3(0, 0.85 * R, 0), Vector3(0, 1.05 * R, 0), Vector3(0.03 * R, 1.25 * R, 0.0), Vector3(0.06 * R, 1.38 * R, 0.0)],
		func(v): return lerpf(0.035, 0.022, v) * R * 3.0, 8, 8, {"bfn": func(u, v, p): return [hA, hB, v], "ow": 0.7})
	for s in [-1.0, 1.0]:
		var base := Vector3(0.06 * R, 1.36 * R, 0.0)
		var dirv := Vector3(s * 1.0, 0.45, 0.15 * s).normalized()
		var side := dirv.cross(Vector3(0, 0, 1)).normalized()
		var LF := func(u: float, v: float) -> Vector3:
			var w := 0.20 * R * sin(v * PI) * (1.0 - 0.25 * v)
			var cup := 0.05 * R * (1.0 - pow((u - 0.5) * 2.0, 2.0))
			return base + dirv * v * 0.48 * R + Vector3(0, -0.10 * R * v * v, 0) + side * (u - 0.5) * 2.0 * w + Vector3(0, cup, 0)
		Geo.patch(c.st("leaf"), LF, 8, 12, {"closed_u": false, "orient": func(u, v, p): return Vector3(0, 1, 0),
			"bfn": func(u, v, p): return [hB, hB, 0.0], "uv2fn": func(u, v, p): return Vector2(0, v),
			"cfn": func(u, v, p): return Color(1.0 if absf(u - 0.5) < 0.06 else 0.0, 0, 0, 0.8)})
	# little curl tail
	var tp := []
	for i in 7:
		var t := i / 6.0
		tp.append(Vector3(0.0, -0.45 * R + 0.35 * R * t, -0.88 * R - 0.25 * R * sin(t * PI * 0.9)) + Vector3(0, 0, 0.12 * R * t * t))
	c.tube("body", tp, func(v): return lerpf(0.10, 0.04, v) * R, 10, 12, {"bfn": func(u, v, p): return [hd, hd, 0.0], "ow": 0.7})
