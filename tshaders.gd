## Toon shader library: cel bands with hue-shifted shadows, soft rim, painted
## gradients/brush noise, inverted-hull ink, painted anime face, chunky toon
## hair with a highlight band, painted sky / grass / far hills.
class_name TShaders
extends RefCounted

const NOISE := """
float hash3(vec3 p){ p = fract(p * 0.3183099 + 0.1); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vnoise3(vec3 x){ vec3 i = floor(x); vec3 f = fract(x); f = f*f*(3.0-2.0*f);
	return mix(mix(mix(hash3(i), hash3(i+vec3(1,0,0)), f.x), mix(hash3(i+vec3(0,1,0)), hash3(i+vec3(1,1,0)), f.x), f.y),
		mix(mix(hash3(i+vec3(0,0,1)), hash3(i+vec3(1,0,1)), f.x), mix(hash3(i+vec3(0,1,1)), hash3(i+vec3(1,1,1)), f.x), f.y), f.z); }
float fbm3(vec3 p){ float v = 0.0; float a = 0.5; for (int i = 0; i < 4; i++){ v += a * vnoise3(p); p = p * 2.07 + 3.1; a *= 0.5; } return v; }
float h11(float x){ return fract(sin(x * 127.1) * 43758.5453); }
float h21(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
"""

## Shared uniforms + cel light(). stage: 0 flat albedo, 1 cel bands, 2 +ink, 3 final (+rim, highlights)
const COMMON := """
uniform vec3 shade : source_color = vec3(0.62, 0.52, 0.70);
uniform vec3 mid : source_color = vec3(0.90, 0.84, 0.88);
uniform float band_a = 0.47;
uniform float band_b = 0.62;
uniform float soft = 0.04;
uniform float stage = 3.0;
uniform float recv = 0.0;
uniform vec3 rim_col : source_color = vec3(1.0, 0.94, 0.82);
uniform float rim_k = 0.45;
uniform vec3 key_dir = vec3(0.45, 0.75, 0.5);
varying float hlv;
float cel(float ndl, float att){
	float t = (ndl * 0.5 + 0.5) * mix(1.0 - 0.38 * recv, 1.0, smoothstep(0.15, 0.6, att));
	return t;
}
vec3 band(float t){
	float m = smoothstep(band_a - soft, band_a + soft, t);
	float l = smoothstep(band_b - soft, band_b + soft, t);
	return mix(shade, mix(mid, vec3(1.0), l), m);
}
vec3 rim_term(vec3 n, vec3 v, mat4 vm){
	vec3 lv = normalize((vm * vec4(normalize(key_dir), 0.0)).xyz);
	float fr = 1.0 - clamp(dot(n, v), 0.0, 1.0);
	float r = smoothstep(0.62, 0.8, fr) * (0.25 + 0.75 * clamp(dot(n, lv) * 0.6 + 0.6, 0.0, 1.0));
	return rim_col * r * rim_k * step(2.5, stage);
}
"""

const LIGHT := """
void light(){
	float t = cel(dot(NORMAL, LIGHT), ATTENUATION);
	vec3 c = stage < 0.5 ? vec3(1.0) : band(t);
	DIFFUSE_LIGHT += c * LIGHT_COLOR;
	float lit = smoothstep(0.5, 0.6, t);
	SPECULAR_LIGHT += LIGHT_COLOR * hlv * lit * step(2.5, stage);
}
"""

## Cloth / props / skin body: painted vertical gradient (UV2.y 0 bottom..1 top),
## trim colour in COLOR.r, low-frequency brush noise on a seam-free param space.
const TOON := """
shader_type spatial;
render_mode cull_back;
uniform vec3 col_a : source_color = vec3(0.5);
uniform vec3 col_b : source_color = vec3(0.7);
uniform vec3 trim : source_color = vec3(0.9, 0.75, 0.35);
uniform float brush = 0.07;
uniform float emit = 0.0;
""" + NOISE + COMMON + """
void vertex(){ }
void fragment(){
	float g = clamp(UV2.y, 0.0, 1.0);
	vec3 c = mix(col_a, col_b, smoothstep(0.0, 1.0, g));
	vec3 q = vec3(cos(UV.x * 6.2832) * 1.5, sin(UV.x * 6.2832) * 1.5, UV.y * 4.0);
	float n = fbm3(q * 1.7 + COLOR.b * 10.0);
	float s = vnoise3(vec3(q.xy * 6.0, q.z * 1.2));
	c *= 1.0 + brush * ((n - 0.5) * 1.4 + (s - 0.5) * 0.6) * step(0.5, stage);
	c = mix(c, trim, COLOR.r);
	ALBEDO = c;
	EMISSION = c * emit + c * rim_term(NORMAL, VIEW, VIEW_MATRIX);
	hlv = 0.0;
}
""" + LIGHT

## Inverted hull ink, constant screen width, thicker away from the key light,
## gently noisy; per-vertex width factor in COLOR.a.
const OUTLINE := """
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
uniform vec3 ink : source_color = vec3(0.17, 0.10, 0.09);
uniform float width = 0.0028;
uniform float on = 1.0;
uniform vec3 key_dir = vec3(0.45, 0.75, 0.5);
""" + NOISE + """
void vertex(){
	vec4 vp = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 vn = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	vec3 lv = normalize((VIEW_MATRIX * vec4(normalize(key_dir), 0.0)).xyz);
	float away = 1.0 - clamp(dot(vn, lv) * 0.5 + 0.5, 0.0, 1.0);
	float n = vnoise3(VERTEX * 18.0);
	float w = width * on * COLOR.a * (0.55 + 0.9 * away) * (0.75 + 0.5 * n);
	vp.xyz += vn * w * clamp(-vp.z, 0.3, 30.0);
	vp.z -= w * 0.6 * clamp(-vp.z, 0.3, 30.0);
	POSITION = PROJECTION_MATRIX * vp;
}
void fragment(){ ALBEDO = ink; }
"""

## Painted anime face on the head surface. UV = head-local (x,y)/R, UV2.x = z/R.
const FACE := """
shader_type spatial;
render_mode cull_back;
uniform vec3 skin : source_color = vec3(1.0, 0.86, 0.74);
uniform vec3 skin_b : source_color = vec3(0.98, 0.80, 0.70);
uniform vec3 blush_col : source_color = vec3(0.98, 0.55, 0.52);
uniform vec3 iris_a : source_color = vec3(0.18, 0.12, 0.10);
uniform vec3 iris_b : source_color = vec3(0.62, 0.40, 0.22);
uniform vec3 brow_col : source_color = vec3(0.30, 0.17, 0.10);
uniform vec3 line_col : source_color = vec3(0.24, 0.12, 0.10);
uniform vec3 mouth_col : source_color = vec3(0.55, 0.20, 0.20);
uniform float eye_x = 0.37;
uniform float eye_y = -0.13;
uniform float eye_w = 0.20;
uniform float eye_h = 0.26;
uniform float brow_y = 0.15;
uniform float mouth_y = -0.56;
uniform float mouth_w = 0.085;
uniform float nose_y = -0.34;
uniform float blink = 0.0;
uniform float mouth = 0.0;
uniform float brow_up = 0.0;
uniform vec2 look = vec2(0.0);
uniform float lashes = 1.0;
varying vec3 hp;
""" + NOISE + COMMON + """
void vertex(){ hp = vec3(UV.x, UV.y, UV2.x); }
float seg(vec2 p, vec2 a, vec2 b){ vec2 pa = p - a, ba = b - a; float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0); return length(pa - ba * h); }
float aa(float d, float w){ return 1.0 - smoothstep(w - 0.006, w + 0.006, d); }
// one eye; q in face units with x pointing outward. returns rgb + coverage
vec4 eye(vec2 q){
	float h0 = eye_h;
	float h = eye_h * (1.0 - blink);
	float w = eye_w;
	vec3 col = vec3(0.0);
	float a = 0.0;
	if (blink > 0.82) {
		// closed: a soft downward arc with a little outer flick
		float x = q.x / w;
		float yc = -0.18 * h0 - 0.16 * h0 * (1.0 - x * x);
		float d = abs(q.y - yc) + max(abs(x) - 1.0, 0.0) * w;
		float th = mix(0.010, 0.020, smoothstep(-1.0, 1.0, x));
		a = aa(d, th);
		return vec4(line_col * 0.8, a);
	}
	float n = 2.4;
	vec2 c0 = vec2(0.0, (h0 - h) * -0.45);
	vec2 s = vec2((q.x - c0.x) / w, (q.y - c0.y) / max(h, 1e-4));
	float r = pow(pow(abs(s.x), n) + pow(abs(s.y), n), 1.0 / n);
	float inside = 1.0 - smoothstep(0.98, 1.02, r);
	// sclera with lid shadow
	vec3 scl = mix(vec3(0.99, 0.98, 0.97), vec3(0.80, 0.80, 0.92), smoothstep(0.2, 0.85, s.y));
	col = scl;
	// iris
	vec2 ic = vec2(look.x * w * 0.25, -0.06 * h0 + look.y * h0 * 0.2);
	vec2 iq = (q - ic) / vec2(0.66 * w, 0.80 * h0);
	float ir = length(iq);
	float ang = atan(iq.y, iq.x);
	vec3 ic1 = mix(iris_a, iris_b, smoothstep(0.55, -0.85, iq.y));
	ic1 *= 1.0 + 0.10 * sin(ang * 16.0) * smoothstep(0.3, 0.8, ir);
	ic1 = mix(ic1, iris_b * 1.35, smoothstep(0.3, 0.9, -iq.y) * smoothstep(0.35, 0.8, ir) * 0.6);
	ic1 = mix(ic1, iris_a * 0.6, smoothstep(0.80, 0.97, ir)); // limbal ring
	float iin = 1.0 - smoothstep(0.97, 1.0, ir);
	col = mix(col, ic1, iin);
	// pupil
	float pr = length((q - ic - vec2(0.0, 0.02 * h0)) / vec2(0.26 * w, 0.36 * h0));
	col = mix(col, iris_a * 0.35, 1.0 - smoothstep(0.92, 1.0, pr));
	// highlights: big upper, small lower, little sparkle
	float hb = length((q - ic - vec2(0.24 * w, 0.30 * h0)) / vec2(0.24 * w, 0.21 * h0));
	float hs = length((q - ic - vec2(-0.26 * w, -0.38 * h0)) / vec2(0.10 * w, 0.08 * h0));
	float hx = length((q - ic - vec2(-0.08 * w, 0.42 * h0)) / vec2(0.06 * w, 0.05 * h0));
	float hl = max(max(1.0 - smoothstep(0.9, 1.0, hb), 1.0 - smoothstep(0.85, 1.0, hs)), 1.0 - smoothstep(0.8, 1.0, hx));
	col = mix(col, vec3(1.0), hl * iin * step(0.5, stage));
	// upper lid shadow on the iris
	col *= 1.0 - 0.28 * smoothstep(0.35, 0.95, s.y);
	a = inside;
	// upper lash line: thick ink on the top boundary, thicker toward the outer corner
	float up = smoothstep(-0.25, 0.15, s.y);
	float tk = mix(0.10, 0.22, smoothstep(-0.6, 1.0, s.x)) * lashes;
	float lash = (1.0 - smoothstep(tk * 0.75, tk, abs(r - 1.0 - tk * 0.35))) * up;
	// outer flick (wing)
	vec2 fa = vec2(w * 0.86, h * 0.30 + c0.y);
	vec2 fb = vec2(w * 1.22, h * 0.52 + c0.y + 0.02);
	float tt = clamp(dot(q - fa, fb - fa) / dot(fb - fa, fb - fa), 0.0, 1.0);
	float fl = aa(seg(q, fa, fb), mix(0.024, 0.004, tt) * lashes);
	lash = max(lash, fl);
	// lower lash: short thin stroke under the outer half
	float low = (1.0 - smoothstep(0.03, 0.06, abs(r - 1.02))) * smoothstep(-0.2, -0.55, s.y) * smoothstep(0.0, 0.5, s.x);
	vec3 lc = line_col * 0.55;
	col = mix(col, lc, lash);
	a = max(a, lash);
	col = mix(col, line_col * 1.4, low * (1.0 - a) * 0.8);
	a = max(a, low * 0.8);
	// double-lid crease
	float cr = (1.0 - smoothstep(0.012, 0.022, abs(r * 1.0 - 1.28))) * smoothstep(0.35, 0.7, s.y) * smoothstep(-0.7, 0.2, s.x) * step(blink, 0.3);
	col = mix(col, line_col * 1.5, cr * (1.0 - a) * 0.6);
	a = max(a, cr * 0.6);
	return vec4(col, a);
}
void fragment(){
	vec3 p = hp;
	float g = smoothstep(-0.8, 0.6, p.y);
	vec3 c = mix(skin_b, skin, g);
	float front = smoothstep(0.15, 0.35, p.z);
	float ax = abs(p.x);
	float sd = sign(p.x);
	// blush ellipses with three little hatch strokes
	vec2 bq = vec2(ax - (eye_x + 0.12), p.y - (eye_y - 0.24));
	float bl = exp(-dot(bq / vec2(0.15, 0.075), bq / vec2(0.15, 0.075)));
	c = mix(c, blush_col, bl * 0.55 * front * step(0.5, stage));
	for (int i = 0; i < 3; i++) {
		float ox = (float(i) - 1.0) * 0.045;
		vec2 a0 = vec2(eye_x + 0.12 + ox + 0.02, eye_y - 0.215);
		vec2 b0 = vec2(eye_x + 0.12 + ox - 0.02, eye_y - 0.265);
		float hd = seg(vec2(ax, p.y), a0, b0);
		c = mix(c, blush_col * 0.8, aa(hd, 0.006) * 0.7 * front * step(0.5, stage));
	}
	// eyes
	vec2 q = vec2((p.x - sd * eye_x) * sd, p.y - eye_y);
	vec4 e = eye(q);
	c = mix(c, e.rgb, e.a * front);
	// brows: short soft arcs
	float bx = q.x / (eye_w * 0.95);
	float by = eye_y + brow_y + eye_h * 0.75 + brow_up * 0.05 + 0.03 * (1.0 - bx * bx) - 0.02 * bx;
	float bt = mix(0.024, 0.008, smoothstep(-1.0, 1.0, bx));
	float bm = (1.0 - smoothstep(bt * 0.6, bt, abs(p.y - by))) * (1.0 - smoothstep(0.85, 1.0, abs(bx)));
	c = mix(c, brow_col, bm * front);
	// nose: tiny shadow-side stroke and a highlight dot
	float ns = aa(seg(p.xy, vec2(0.025, nose_y + 0.035), vec2(0.04, nose_y - 0.01)), 0.008);
	c = mix(c, line_col * 1.8, ns * 0.55 * front);
	// mouth
	float mx = p.x / mouth_w;
	if (mouth < 0.5) {
		float my = mouth_y + 0.035 * mx * mx;
		float th = 0.011 * (1.0 - 0.6 * mx * mx);
		float mm = aa(abs(p.y - my), th) * (1.0 - smoothstep(0.95, 1.05, abs(mx)));
		c = mix(c, line_col, mm * front);
	} else {
		float mw = mouth_w * 1.15;
		float x2 = p.x / mw;
		float top = mouth_y + 0.02 + 0.015 * x2 * x2;
		float bot = mouth_y + 0.02 - 0.095 * (1.0 - x2 * x2);
		float insd = step(abs(x2), 1.0) * step(p.y, top) * step(bot, p.y);
		vec3 mc = mix(mouth_col, vec3(0.95, 0.55, 0.55), smoothstep(bot + 0.045, bot + 0.01, p.y));
		c = mix(c, mc, insd * front);
		float edge = min(abs(p.y - top), abs(p.y - bot));
		float ol = aa(edge, 0.008) * step(abs(x2), 1.02) * step(bot - 0.01, p.y) * step(p.y, top + 0.01);
		c = mix(c, line_col, ol * front);
	}
	ALBEDO = c;
	EMISSION = c * rim_term(NORMAL, VIEW, VIEW_MATRIX);
	hlv = 0.0;
}
""" + LIGHT

## Chunky locks: flat colour, darker roots, toon highlight band (head-local
## latitude with a zigzag, broken per lock). UV=(x,y)/R, UV2=(z/R, along).
const HAIR := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 hair : source_color = vec3(0.45, 0.28, 0.16);
uniform vec3 hair_dark : source_color = vec3(0.30, 0.17, 0.10);
uniform vec3 hi_col : source_color = vec3(0.55, 0.45, 0.32);
uniform float hl_y = 0.50;
uniform float hl_w = 0.07;
""" + NOISE + COMMON + """
varying vec3 hp;
varying float lock_id;
void vertex(){ hp = vec3(UV.x, UV.y, UV2.x); lock_id = COLOR.g; }
void fragment(){
	float along = UV2.y;
	vec3 c = mix(hair_dark, hair, smoothstep(0.0, 0.5, along) * 0.6 + 0.4 * smoothstep(-0.6, 0.6, hp.y));

	float az = atan(hp.x, hp.z);
	float yb = hl_y + 0.05 * sin(az * 9.0 + 1.0) + 0.025 * sin(az * 23.0);
	float hb = 1.0 - smoothstep(hl_w * 0.55, hl_w, abs(hp.y - yb));
	hb *= smoothstep(0.3, 0.6, vnoise3(vec3(az * 6.0, 0.0, 2.0))) * smoothstep(-0.2, 0.3, hp.z + 0.2);
	ALBEDO = c;
	EMISSION = c * rim_term(NORMAL, VIEW, VIEW_MATRIX);
	hlv = hb;
	if (!FRONT_FACING) { ALBEDO *= 0.75; hlv = 0.0; }
}
void light(){
	float t = cel(dot(NORMAL, LIGHT), ATTENUATION);
	vec3 c = stage < 0.5 ? vec3(1.0) : band(t);
	DIFFUSE_LIGHT += c * LIGHT_COLOR;
	float lit = smoothstep(-0.1, 0.25, dot(NORMAL, LIGHT));
	SPECULAR_LIGHT += LIGHT_COLOR * hi_col * hlv * lit * step(2.5, stage);
}
"""

## Ghibli-ish painted sky: deep zenith blue to pale horizon, puffy cumulus with
## lavender undersides and warm sunlit tops, a soft sun glow.
const SKY := """
shader_type sky;
uniform vec3 sun_dir = vec3(0.45, 0.75, 0.5);
""" + NOISE + """
float fbm2(vec2 p){ return fbm3(vec3(p, 0.5)); }
void sky(){
	vec3 d = EYEDIR;
	float el = d.y;
	vec3 zen = vec3(0.16, 0.42, 0.78);
	vec3 hor = vec3(0.70, 0.86, 0.95);
	vec3 c = mix(hor, zen, pow(smoothstep(-0.05, 0.75, el), 0.7));
	c = mix(c, vec3(0.92, 0.95, 0.90), exp(-max(el, 0.0) * 18.0) * 0.5);
	float sd = max(dot(d, normalize(sun_dir)), 0.0);
	c += vec3(1.0, 0.95, 0.8) * pow(sd, 18.0) * 0.25;
	// cumulus band: (azimuth, elevation) noise, flat bottoms, billowy tops
	float az = atan(d.x, -d.z);
	vec2 cp = vec2(az * 2.2, el * 7.0);
	float base = 0.06 + 0.10 * fbm2(vec2(az * 1.3, 2.0));
	float hgt = el - base;
	float dens = fbm2(cp * 1.4 + vec2(0.0, -hgt * 2.0)) * 1.3 + fbm2(cp * 3.7) * 0.35;
	dens -= 0.62 + 1.6 * max(hgt - 0.10, 0.0) + 8.0 * max(-hgt, 0.0);
	float cov = smoothstep(0.0, 0.06, dens) * smoothstep(-0.02, 0.03, el);
	// shading: sample toward the sun to fake light within the cloud
	float dens2 = fbm2(cp * 1.4 + vec2(0.0, -hgt * 2.0) + vec2(0.06, 0.12)) * 1.3 + fbm2(cp * 3.7 + vec2(0.1, 0.3)) * 0.35;
	float lit = clamp(0.5 + (dens - (dens2 - 0.62 - 1.6 * max(hgt - 0.10, 0.0))) * 6.0, 0.0, 1.0);
	vec3 cl = mix(vec3(0.70, 0.72, 0.86), vec3(1.0, 0.99, 0.95), smoothstep(0.25, 0.7, lit) * 0.7 + 0.3 * smoothstep(0.0, 0.15, hgt));
	c = mix(c, cl, cov);
	// high wispy streaks
	float wisp = smoothstep(0.62, 0.8, fbm2(vec2(d.x / max(el, 0.05) * 0.8, d.z / max(el, 0.05) * 3.0))) * smoothstep(0.25, 0.6, el) * 0.35;
	c = mix(c, vec3(0.97, 0.98, 1.0), wisp);
	COLOR = c;
}
"""

## Grass meadow: cel-lit, painted clumps, brush dabs, flower specks.
const GRASS := """
shader_type spatial;
uniform vec3 g_lit : source_color = vec3(0.50, 0.68, 0.30);
uniform vec3 g_dark : source_color = vec3(0.30, 0.50, 0.24);
uniform vec3 g_far : source_color = vec3(0.55, 0.70, 0.42);
varying vec3 wp;
""" + NOISE + COMMON + """
void vertex(){ wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment(){
	float dist = length(wp.xz);
	float n = fbm3(vec3(wp.xz * 0.45, 0.0));
	float n2 = vnoise3(vec3(wp.x * 2.5, wp.z * 2.5, 1.0));
	vec3 c = mix(g_dark, g_lit, smoothstep(0.35, 0.65, n * 0.8 + n2 * 0.4));
	// brush dabs: short strokes, slightly lighter / yellower
	float st = vnoise3(vec3(wp.x * 14.0, wp.z * 5.0, 3.0));
	c = mix(c, c * vec3(1.08, 1.06, 0.90), smoothstep(0.62, 0.75, st) * 0.6);
	c = mix(c, g_far, smoothstep(6.0, 40.0, dist));
	// flowers
	vec2 cell = floor(wp.xz * 3.0);
	vec2 f = fract(wp.xz * 3.0) - 0.5;
	float hsh = h21(cell);
	vec2 off = vec2(h21(cell + 7.0), h21(cell + 13.0)) - 0.5;
	float fd = length(f - off * 0.6);
	float flower = (1.0 - smoothstep(0.045, 0.07, fd)) * step(0.93, hsh) * (1.0 - smoothstep(4.0, 9.0, dist));
	vec3 fc = hsh > 0.975 ? vec3(1.0, 0.85, 0.35) : vec3(1.0, 0.98, 0.95);
	c = mix(c, fc, flower);
	ALBEDO = c;
	hlv = 0.0;
}
""" + LIGHT

## Far hills / tree masses: painted, unlit gradient with aerial haze.
const FAR := """
shader_type spatial;
render_mode unshaded;
uniform vec3 base : source_color = vec3(0.42, 0.60, 0.40);
uniform vec3 top : source_color = vec3(0.60, 0.74, 0.48);
uniform vec3 haze : source_color = vec3(0.70, 0.84, 0.92);
uniform float hz = 0.3;
varying vec3 wp;
""" + NOISE + """
void vertex(){ wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment(){
	float g = smoothstep(0.0, 1.0, UV.y);
	vec3 c = mix(base, top, g);
	c *= 0.94 + 0.12 * fbm3(vec3(wp.x * 0.15, wp.y * 0.6, wp.z * 0.15));
	c = mix(c, haze, hz);
	ALBEDO = c;
}
"""
