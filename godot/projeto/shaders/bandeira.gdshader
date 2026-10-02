// Bandeira de adeptos a ondular: duas cores em faixas, ondas que correm do mastro para a ponta.
shader_type spatial;
render_mode cull_disabled;
uniform vec3 cor1 = vec3(0.2, 0.4, 0.9);
uniform vec3 cor2 = vec3(0.95, 0.95, 0.95);
uniform float fase = 0.0;
uniform float vento = 1.0;
uniform float faixas = 3.0;
void vertex() {
	float u = UV.x;                         // 0 no mastro, 1 na ponta
	float w = sin(TIME * 4.0 * vento + fase - u * 6.0) * 0.28 * u + sin(TIME * 7.3 + fase + UV.y * 4.0 - u * 9.0) * 0.06 * u;
	VERTEX.z += w;
	VERTEX.y -= u * u * 0.25 * (1.2 - vento);
}
void fragment() {
	float f = step(0.5, fract(UV.y * faixas * 0.5));
	vec3 c = mix(cor1, cor2, f);
	ALBEDO = c * (0.85 + 0.15 * sin(UV.x * 20.0 + TIME * 4.0 + fase));
	ROUGHNESS = 0.8;
}
