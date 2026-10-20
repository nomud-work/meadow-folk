## Chunky toon hair: an offset scalp cap plus smooth clumped locks (flattened
## tapering tubes that hug the head, then fall), each carrying a lock id for
## the highlight-band breakup.
class_name THair
extends RefCounted

var h: THead
var c: TChar
var rng := RandomNumberGenerator.new()
var n_locks := 0

func _init(ch: TChar, seed: int) -> void:
	c = ch; h = ch.head; rng.seed = seed

func cap(key: String, off: float, hairline: Callable, bone: String) -> void:
	var P := func(u: float, v: float) -> Vector3:
		var az := (u - 0.5) * TAU
		var pol: float = lerpf(0.02, hairline.call(az), v)
		return h.world(h.trace(THead.scalp_dir(az, pol), off))
	Geo.patch(c.st(key), P, 64, 22, {"closed_u": true, "bfn": c.rigid(bone),
		"nfn": func(u, v, p): return h.grad(h.local(p)),
		"uvfn": func(u, v, p): var q = h.local(p); return Vector2(q.x, q.y),
		"uv2fn": func(u, v, p): var q = h.local(p); return Vector2(q.z, 0.0),
		"cfn": func(u, v, p): return Color(0, 0.5, 0, 0.0)})

## o: off, grav, bias (Vector3, R units/step direction), curl (Vector3 added
## growing toward the tip), w (width, R units), thick, n
func lock(key: String, az: float, pol: float, length: float, o := {}) -> void:
	var off: float = o.get("off", 0.07)
	var n: int = o.get("n", 16)
	var grav: float = o.get("grav", 0.35)
	var bias: Vector3 = o.get("bias", Vector3.ZERO)
	var curl: Vector3 = o.get("curl", Vector3.ZERO)
	var w0: float = o.get("w", 0.26)
	var th0: float = o.get("thick", 0.10)
	var q := h.trace(THead.scalp_dir(az, pol), off * 0.5)
	var d := Vector3(cos(pol) * sin(az), -sin(pol), cos(pol) * cos(az))
	if o.has("dir0"): d = (o.dir0 as Vector3).normalized()
	var step := length / n
	var pts := [q]
	for i in n:
		var t := float(i) / n
		d = (d + bias * 0.4 + Vector3(0, -1, 0) * grav * (0.3 + t) * 0.5 + curl * t * t).normalized()
		var nq := q + d * step
		var dd := h.sdf(nq) - off * (1.0 + 0.6 * t)
		if dd < 0.0:
			nq -= h.grad(nq) * dd
		d = (nq - q).normalized()
		q = nq
		pts.append(q)
	var lid := rng.randf()
	n_locks += 1
	var cen := Vector3(0, 0.1, -0.05)
	var sample := func(v: float) -> Array:
		var f := v * n
		var j := mini(int(f), n - 1)
		var s := f - j
		var p: Vector3 = (pts[j] as Vector3).lerp(pts[j + 1], s)
		var T: Vector3 = (pts[j + 1] - pts[j]).normalized()
		var O: Vector3 = (p - cen)
		O = (O - T * T.dot(O)).normalized()
		return [p, T, O, T.cross(O)]
	var P := func(u: float, v: float) -> Vector3:
		var a: Array = sample.call(v)
		var th := u * TAU
		var taper := pow(maxf(1.0 - v, 0.0), 0.75) * (0.9 + 0.25 * sin(minf(v * 2.0, 1.0) * PI * 0.5))
		var wx := w0 * taper
		var wy := th0 * taper * (1.0 - 0.2 * pow(cos(th), 2.0))
		return h.world((a[0] as Vector3) + (a[3] as Vector3) * cos(th) * wx + (a[2] as Vector3) * sin(th) * wy)
	var bfn: Callable = o.get("bfn", c.rigid("head"))
	Geo.patch(c.st(key), P, 14, n * 2, {"closed_u": true, "bfn": bfn,
		"orient": func(u, v, p): var a = sample.call(v); return h.local(p) - (a[0] as Vector3),
		"uvfn": func(u, v, p): var qq = h.local(p); return Vector2(qq.x, qq.y),
		"uv2fn": func(u, v, p): var qq = h.local(p); return Vector2(qq.z, v),
		"cfn": func(u, v, p): return Color(0, lid, 0, lerpf(1.0, 0.35, v))})
