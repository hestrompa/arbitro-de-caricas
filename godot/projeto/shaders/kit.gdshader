// Jogador: pele do MakeHuman e equipamento pintado por partes do corpo e altura de repouso (igual à versão browser)
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D skin_tex : source_color, filter_linear_mipmap;
uniform vec3 shirt : source_color = vec3(0.21, 0.41, 0.86);
uniform vec3 shirt2 : source_color = vec3(0.95);
uniform vec3 shorts : source_color = vec3(0.95);
uniform vec3 sock : source_color = vec3(0.11, 0.25, 0.56);
uniform vec3 trim : source_color = vec3(0.11, 0.25, 0.56);
uniform vec3 hair : source_color = vec3(0.16, 0.1, 0.06);
uniform float pat = 0.0;
uniform float bald = 0.0;
uniform vec4 cut = vec4(0.967, 0.534, 0.077, 1.437); // anca, joelho, pé, ombro
uniform float flutter = 0.0;   // 0 parado, 1 a correr: o tecido da camisola e dos calções ondula
uniform float phase = 0.0;
varying float cloth;
// tecido: a camisola e os calções ondulam com a corrida (mais solto em baixo e nas mangas)
void vertex() {
	float y = UV2.y;
	bool arm = COLOR.r > 0.5, leg = COLOR.g > 0.5, head = COLOR.b > 0.5;
	float m = 0.0;
	if (!head && !arm && !leg && y > cut.x - 0.05 && y < cut.w + 0.05) m = 0.4 + 0.6 * smoothstep(cut.x + 0.35, cut.x - 0.05, y);
	if (arm && y > cut.w - 0.2) m = 0.7;
	if (leg && y > cut.y + 0.16 && y < cut.x + 0.02) m = 0.8;
	float t = TIME * (5.0 + 7.0 * flutter) + phase;
	float w = sin(t + y * 23.0 + UV2.x * 11.0) * 0.6 + sin(t * 1.7 - y * 37.0 + UV2.x * 19.0) * 0.4;
	VERTEX += NORMAL * w * m * (0.0025 + 0.0085 * flutter);
	cloth = m;
}
void fragment() {
	vec3 c = texture(skin_tex, UV).rgb;
	float x = UV2.x, y = UV2.y, rough = 0.62, sheen = 0.0;
	bool arm = COLOR.r > 0.5, leg = COLOR.g > 0.5, head = COLOR.b > 0.5, hairv = COLOR.a > 0.25 && COLOR.a < 0.75, eye = COLOR.a > 0.75;
	vec3 shirtC = shirt;
	if (pat > 0.5 && pat < 1.5 && fract((x + 0.5) * 8.0) > 0.5) shirtC = shirt2;
	if (pat > 1.5 && pat < 2.5 && fract(y * 7.0) > 0.5) shirtC = shirt2;
	if (pat > 2.5 && pat < 3.5 && abs(x * 0.95 - (y - 1.27)) < 0.06) shirtC = shirt2;
	if (pat > 3.5 && pat < 4.5 && x > 0.0) shirtC = shirt2;
	if (eye) { c = vec3(0.07, 0.05, 0.04); rough = 0.2; }
	else if (hairv && bald < 0.5) { c = hair * (0.8 + 0.4 * c.g); rough = 0.9; }
	else if (head) { }
	else if (arm) { if (y > cut.w - 0.2) { c = pat > 4.5 ? shirt2 : (pat > 3.5 && x > 0.0 ? shirt2 : shirt); if (y < cut.w - 0.175) c = trim; rough = 0.8; sheen = 1.0; } }
	else if (leg) {
		if (y < cut.z + 0.035) discard;
		else if (y < cut.y - 0.08) { c = y > cut.y - 0.115 ? trim : sock; rough = 0.9; }
		else if (y < cut.y + 0.16) { }
		else { c = (abs(abs(x) - 0.135) < 0.012 && abs(x) > 0.1) ? trim : shorts; rough = 0.75; sheen = 1.0; }
	} else if (y > cut.w + 0.085) { }
	else { c = y > cut.x + 0.11 ? (y > cut.w + 0.06 ? trim : shirtC) : shorts; rough = 0.8; sheen = 1.0; }
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = sheen > 0.5 ? 0.35 : 0.5;
}
