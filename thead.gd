## Rounded toon head / spirit body as a small SDF (units of R), sphere-traced
## from outside along lat-long directions (poles on the ear axis, so the face
## has no pole). Also scalp helpers used by the chunky hair.
class_name THead
extends RefCounted

var kind := "kid"
var R := 0.12
var c := Vector3.ZERO # centre (model space)
var P := {}

func _init(kind_: String, R_: float, c_: Vector3, params := {}) -> void:
	kind = kind_; R = R_; c = c_
	P = {"jaw": 1.0, "chin": 1.0, "cheek": 1.0, "nose": 1.0, "flat": 0.93, "long": 1.0}
	for k in params: P[k] = params[k]

static func ell(p: Vector3, o: Vector3, r: Vector3) -> float:
	var q := (p - o) / r
	var k0 := q.length()
	var k1 := (q / r).length()
	return k0 * (k0 - 1.0) / maxf(k1, 1e-6)

static func smin(a: float, b: float, k: float) -> float:
	var h := clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)

static func smax(a: float, b: float, k: float) -> float:
	return -smin(-a, -b, k)

## p in R units, head-local
func sdf(p: Vector3) -> float:
	if kind == "spirit":
		var d := ell(p, Vector3(0, 0.05, 0), Vector3(1.0, 0.88, 0.92))
		d = smin(d, ell(p, Vector3(0, -0.30, 0.0), Vector3(1.08, 0.62, 0.98)), 0.35)
		d = smin(d, ell(p, Vector3(0, 0.82, -0.02), Vector3(0.16, 0.26, 0.16)), 0.30)
		d = smax(d, -(p.y + 0.86), 0.12) # soft flat-ish base
		return d
	var lg: float = P.long
	var d := ell(p, Vector3(0, 0.06, -0.03), Vector3(1.0, 0.97, 0.98))
	d = smin(d, ell(p, Vector3(0, -0.36 * lg, 0.14), Vector3(0.68 * P.jaw, 0.52 * lg, 0.68)), 0.30)
	d = smin(d, ell(p, Vector3(0, -0.64 * lg, 0.36), Vector3(0.24 * P.chin, 0.19, 0.24)), 0.24)
	for s in [-1.0, 1.0]:
		d = smin(d, ell(p, Vector3(s * 0.40, -0.30 * lg, 0.44), Vector3(0.32, 0.25, 0.30) * P.cheek), 0.16)
	d = smax(d, p.z - P.flat, 0.16) # flatter face plane (anime)
	d = smin(d, ell(p, Vector3(0, -0.32 * lg, P.flat - 0.03), Vector3(0.055, 0.07, 0.06) * P.nose), 0.06)
	return d

func grad(p: Vector3) -> Vector3:
	var e := 0.002
	var k1 := Vector3(1, -1, -1); var k2 := Vector3(-1, -1, 1)
	var k3 := Vector3(-1, 1, -1); var k4 := Vector3(1, 1, 1)
	return (k1 * sdf(p + k1 * e) + k2 * sdf(p + k2 * e) + k3 * sdf(p + k3 * e) + k4 * sdf(p + k4 * e)).normalized()

static func dir(u: float, v: float) -> Vector3:
	var ph := v * PI
	var th := u * TAU
	return Vector3(-cos(ph), sin(ph) * cos(th), sin(ph) * sin(th))

## trace from outside along d; returns R-unit point at offset (R units)
func trace(d: Vector3, off := 0.0) -> Vector3:
	var r := 2.2
	for i in 80:
		var dist := sdf(d * r) - off
		if dist < 0.0005: break
		r -= maxf(dist * 0.9, 0.0003)
	return d * r

## model-space point -> R-unit local
func local(p: Vector3) -> Vector3:
	return (p - c) / R

func world(q: Vector3) -> Vector3:
	return c + q * R

## push a model-space point out of the head (offset in R units)
func push_out(p: Vector3, off: float) -> Vector3:
	var q := local(p)
	for i in 4:
		var d := sdf(q) - off
		if d >= 0.0: break
		q -= grad(q) * d * 1.05
	return world(q)

func build(st: SurfaceTool, nu: int, nv: int, bone: int) -> void:
	var Pf := func(u: float, v: float) -> Vector3: return world(trace(dir(u, v)))
	Geo.patch(st, Pf, nu, nv, {
		"closed_u": true,
		"nfn": func(u, v, p): return grad(local(p)),
		"uvfn": func(u, v, p): var q = local(p); return Vector2(q.x, q.y),
		"uv2fn": func(u, v, p): var q = local(p); return Vector2(q.z, 0.0),
		"bones": [bone],
	})

static func scalp_dir(az: float, pol: float) -> Vector3:
	return Vector3(sin(pol) * sin(az), cos(pol), sin(pol) * cos(az))
