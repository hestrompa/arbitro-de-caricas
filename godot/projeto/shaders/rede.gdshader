// Rede da baliza: malha de fios em losango (UV em metros), transparente entre os fios, a abanar um pouco.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, shadows_disabled;
uniform float malha = 0.12;      // lado da malha (m)
uniform float fio = 0.012;       // espessura do fio (m)
uniform float abana = 0.0;       // 0..1: bola na rede
void vertex() {
	float f = UV2.x;              // 0 nos postes, 1 longe deles (onde a rede cede)
	VERTEX += NORMAL * f * (0.04 * sin(TIME * 1.3 + VERTEX.z * 0.7) + abana * 0.25 * sin(TIME * 18.0 - length(VERTEX.yz) * 3.0));
}
void fragment() {
	vec2 u = UV / malha;
	u = vec2(u.x + u.y, u.x - u.y) * 0.7071;   // losangos
	vec2 g = abs(fract(u) - 0.5);
	vec2 fw = fwidth(u);
	float dl = 0.5 - max(g.x, g.y);    // distância ao fio mais perto (em malhas)
	float l = 1.0 - smoothstep(fio / malha, fio / malha + fw.x * 1.5, dl);
	// ao longe os fios fundem-se num véu
	float longe = clamp(length(fw) * 6.0, 0.0, 1.0);
	ALBEDO = vec3(0.95);
	ROUGHNESS = 0.8;
	ALPHA = mix(l * 0.95, 0.22, longe);
}
