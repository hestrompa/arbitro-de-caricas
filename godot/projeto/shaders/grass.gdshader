// relva com volume: tufos curtos que abanam com o vento (só na versão de computador)
shader_type spatial;
render_mode cull_disabled;
varying float hgt;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	hgt = UV.y;
	float w = sin(TIME * 1.8 + wp.x * 0.35 + wp.z * 0.21) * 0.5 + sin(TIME * 3.1 + wp.x * 1.3) * 0.25;
	VERTEX.x += w * 0.012 * UV.y * UV.y;
	VERTEX.z += w * 0.008 * UV.y * UV.y;
}
void fragment() {
	vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float stripe = mod(floor(wp.x / 5.25), 2.0) < 0.5 ? 0.0 : 1.0;
	vec3 g1 = vec3(0.035, 0.17, 0.02), g2 = vec3(0.05, 0.225, 0.03);
	vec3 c = mix(g1, g2, stripe) * (0.75 + 0.35 * hgt);
	ALBEDO = c;
	ROUGHNESS = 0.85;
	BACKLIGHT = vec3(0.02, 0.05, 0.01);
	SPECULAR = 0.2;
}
