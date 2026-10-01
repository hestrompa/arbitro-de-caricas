// relva com volume: tufos curtos que abanam com o vento (só na versão de computador)
shader_type spatial;
render_mode cull_disabled;
varying float hgt;
// as linhas pintadas do campo ficam à vista (sem tufos por cima)
bool on_line(vec2 p) {
	const float W = 105.0, H = 68.0, w = 0.16;
	if (p.x < -0.2 || p.x > W + 0.2 || p.y < -0.2 || p.y > H + 0.2) return false;
	if (abs(p.x) < w || abs(p.x - W) < w || abs(p.y) < w || abs(p.y - H) < w || abs(p.x - W * 0.5) < w) return true;
	if (abs(length(p - vec2(W * 0.5, H * 0.5)) - 9.15) < w) return true;
	for (int s = 0; s < 2; s++) {
		float rx = s == 0 ? p.x : W - p.x, ay = abs(p.y - H * 0.5);
		if (abs(rx - 16.5) < w && ay < 20.2) return true;
		if (abs(ay - 20.16) < w && rx < 16.5) return true;
		if (abs(rx - 5.5) < w && ay < 9.2) return true;
		if (abs(ay - 9.16) < w && rx < 5.5) return true;
		if (rx > 16.5 && abs(length(vec2(rx - 11.0, p.y - H * 0.5)) - 9.15) < w) return true;
	}
	return false;
}
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	hgt = UV.y;
	if (on_line(wp.xz)) VERTEX *= 0.0;
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
