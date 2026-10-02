// Cabelo e pelos da cara (proxies do MakeHuman): a textura dá o desenho dos fios e a transparência,
// a cor vem do uniforme (a mesma para cabelo e sobrancelhas de cada jogador).
shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 hair : source_color = vec3(0.16, 0.1, 0.06);
uniform float ref_lum = 0.15;      // luminância média da textura (para normalizar o desenho)
uniform float cutoff = 0.5;
uniform bool hidden = false;
void fragment() {
	if (hidden) discard;
	vec4 t = texture(tex, UV);
	if (t.a < cutoff) discard;
	float l = dot(t.rgb, vec3(0.3, 0.59, 0.11));
	ALBEDO = hair * clamp(0.55 + 0.45 * l / ref_lum, 0.3, 1.6);
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
}
