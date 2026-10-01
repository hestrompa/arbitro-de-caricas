// Bancadas: público em grelha com cores das equipas, a mexer
shader_type spatial;
uniform vec3 home : source_color = vec3(0.21, 0.41, 0.86);
uniform vec3 away : source_color = vec3(0.93, 0.49, 0.17);
uniform float mix_home = 0.7;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 cell = floor(vec2(wp.x + wp.z, wp.y) * vec2(1.6, 2.2));
	float h = hash(cell), h2 = hash(cell + 3.7);
	vec3 seat = vec3(0.16, 0.18, 0.22);
	vec3 shirtc = h < mix_home ? home : (h < mix_home + 0.15 ? away : vec3(0.9, 0.9, 0.85) * (0.5 + 0.5 * h2));
	vec2 f = fract(vec2(wp.x + wp.z, wp.y) * vec2(1.6, 2.2));
	float bob = 0.08 * sin(TIME * (2.0 + 3.0 * h2) + h * 30.0);
	float person = step(0.18, f.x) * step(f.x, 0.82) * step(0.12 + bob, f.y) * step(f.y, 0.85 + bob) * step(0.12, h2);
	float headm = step(0.3, f.x) * step(f.x, 0.7) * step(0.7 + bob, f.y);
	vec3 c = mix(seat, shirtc, person);
	c = mix(c, vec3(0.75, 0.55, 0.42) * (0.6 + 0.6 * h), headm * person);
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
