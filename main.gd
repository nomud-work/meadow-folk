## Render driver. --mode=hero|face|group|movie|breakdown|wire --char=boy|girl|spirit --out=name
##   --stage=0..3 (breakdown: flat / cel / +ink / final) --t=seconds (pose time)
extends Node3D

var chars := []
var cam: Camera3D
var mode := "hero"
var who := "boy"
var out_name := ""
var frame := 0
var timings := PackedFloat64Array()
var last := 0
var stage := 3.0
var t_pose := 1.0

func _arg(k: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + k + "="): return a.substr(k.length() + 3)
	return d

func make(kind: String) -> TChar:
	var tc := Time.get_ticks_msec()
	var c := TChar.new()
	c.kind = kind
	c.phase = {"boy": 0.0, "girl": 1.7, "spirit": 3.1}[kind]
	match kind:
		"boy": Designs.boy(c)
		"girl": Designs.girl(c)
		_: Designs.spirit(c)
	c.commit()
	add_child(c)
	print("BUILD %s ms=%d tris=%d" % [kind, Time.get_ticks_msec() - tc, c.total_tris()])
	print("TRIS %s %s" % [kind, c.tris])
	return c

func _ready() -> void:
	mode = _arg("mode", "hero")
	who = _arg("char", "boy")
	out_name = _arg("out", mode + "_" + who)
	stage = float(_arg("stage", "3"))
	t_pose = float(_arg("t", "1.0"))
	var t0 := Time.get_ticks_msec()
	TScene.build(self, true)
	var list: Array = ["boy", "girl", "spirit"] if mode in ["group", "movie"] else [who]
	for k in list: chars.append(make(k))
	print("BUILD_TOTAL_MS ", Time.get_ticks_msec() - t0)
	cam = Camera3D.new(); add_child(cam); cam.make_current()
	var hero_pos := {"boy": Vector3(0, 0, 0), "girl": Vector3(0, 0, 0), "spirit": Vector3(0, 0.42, 0)}
	if list.size() == 1:
		var c: TChar = chars[0]
		c.position = hero_pos[who]
		c.rotation.y = float(_arg("yaw", "0.45"))
		var hc: Vector3 = c.head.c + c.position
		match mode:
			"hero", "breakdown", "wire":
				var ht := 1.15 if who != "spirit" else 0.55
				cam.fov = 30.0
				var look := Vector3(0, ht * 0.50 + c.position.y * 0.6, 0)
				if who == "spirit": look = Vector3(0, 0.42, 0)
				cam.look_at_from_position(look + Vector3(0.0, 0.06, ht * 2.25 + 0.4), look)
			"face":
				cam.fov = 22.0
				c.rotation.y = 0.35
				var fc := hc + Vector3(0, -0.01, 0)
				cam.look_at_from_position(fc + Vector3(0.0, 0.02, 0.85), fc)
		c.wave = 1.0 if who == "boy" else 0.0
		c.mouth = 1.0 if who != "girl" else 0.0
		if who == "girl": c.pose = {"tilt": -0.10}
	else:
		chars[0].position = Vector3(-0.40, 0, 0.05); chars[0].rotation.y = 0.28
		chars[1].position = Vector3(0.42, 0, -0.05); chars[1].rotation.y = -0.30
		chars[2].position = Vector3(0.0, 0.40, 0.32); chars[2].rotation.y = 0.1
		cam.fov = 34.0
		cam.look_at_from_position(Vector3(0.0, 0.62, 3.0), Vector3(0, 0.66, 0))
	for m in TChar.registry:
		var sm := m as ShaderMaterial
		if sm.shader.code.contains("uniform float stage"):
			sm.set_shader_parameter("stage", stage)
		if sm.shader.code.contains("uniform float on"):
			sm.set_shader_parameter("on", 1.0 if stage >= 1.5 else 0.0)
	for c in chars: c.idle(t_pose)
	if mode == "movie": Engine.max_fps = 0

func _process(_d: float) -> void:
	frame += 1
	var now := Time.get_ticks_usec()
	if last > 0: timings.append((now - last) / 1000.0)
	last = now
	if mode == "movie":
		var t := frame / 30.0
		var c0: TChar = chars[0]; var c1: TChar = chars[1]; var c2: TChar = chars[2]
		c0.wave = smoothstep(2.3, 3.0, t) * (1.0 - smoothstep(6.6, 7.3, t))
		c0.mouth = 1.0 if (t > 2.6 and t < 7.0) else 0.0
		c1.pose = {"tilt": -0.12 * smoothstep(3.5, 4.3, t) * (1.0 - smoothstep(8.0, 8.8, t))}
		c1.mouth = 1.0 if (t > 4.0 and t < 8.2) else 0.0
		c2.wave = smoothstep(5.0, 5.4, t) * (1.0 - smoothstep(7.5, 8.0, t))
		c2.mouth = 1.0 if (t > 5.0 and t < 8.0) else 0.0
		for c in chars: c.idle(t)
		if frame % 30 == 0: print("FRAME ", frame)
		if frame in [60, 135, 200]:
			get_viewport().get_texture().get_image().save_png("res://out/movie_f%d.png" % frame)
		return
	if frame == 6:
		get_viewport().get_texture().get_image().save_png("res://out/" + out_name + ".png")
		var s := timings.duplicate(); s.sort()
		print("STILL ", out_name, " frame_ms_median=", s[s.size() / 2] if s.size() > 0 else 0.0)
		get_tree().quit()

func _exit_tree() -> void:
	if mode == "movie" and timings.size() > 0:
		var s: PackedFloat64Array = timings.duplicate(); s.sort()
		print("FRAME_MS median=%.1f p95=%.1f n=%d" % [s[s.size() / 2], s[int(s.size() * 0.95)], s.size()])
