// Relvado: faixas de corte, ruído de relva e linhas do campo (105 x 68 m) desenhadas no shader
shader_type spatial;
uniform vec3 g1 = vec3(0.035, 0.17, 0.02);
uniform vec3 g2 = vec3(0.05, 0.225, 0.03);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y); }
// linhas com antialias pela derivada: nítidas de perto, sem serrilhado ao longe
float line(float d, float w) { float fw = max(fwidth(d), 0.004); return 1.0 - smoothstep(w * 0.5 - fw * 0.5, w * 0.5 + fw, abs(d)); }
void fragment() {
	vec2 p = wp.xz; const float W = 105.0, H = 68.0, lw = 0.12;
	// faixas de corte: a relva deitada para um lado ou para o outro brilha conforme o lado de onde se olha
	float faixa = mod(floor(p.x / 5.25), 2.0) < 0.5 ? 1.0 : -1.0;
	vec2 olhar = normalize(wp.xz - CAMERA_POSITION_WORLD.xz + vec2(0.0001));
	float brilho = 0.5 + faixa * (0.4 + 0.1 * olhar.x);
	vec3 c = mix(g1, g2, clamp(brilho, 0.0, 1.0));
	// variação: manchas grandes, tufos e fios de relva
	c *= 0.86 + 0.18 * noise(p * 0.35 + 3.0) + 0.08 * noise(p * 2.5) + 0.06 * (hash(floor(p * 40.0)) - 0.5);
	c = mix(c, c * vec3(1.08, 1.04, 0.8), 0.35 * smoothstep(0.55, 0.85, noise(p * 0.08 + 11.0)));
	// relva gasta: pequena área, marca de penálti e grande círculo
	float gasto = 0.0;
	for (int s = 0; s < 2; s++) {
		float gx = s == 0 ? 0.0 : W;
		vec2 q = vec2(abs(p.x - gx), p.y - H * 0.5);
		gasto = max(gasto, (1.0 - smoothstep(0.0, 4.5, length(q * vec2(1.0, 0.55)))) * 0.85);
		gasto = max(gasto, (1.0 - smoothstep(0.0, 1.6, length(q - vec2(11.0, 0.0)))) * 0.7);
	}
	gasto = max(gasto, (1.0 - smoothstep(0.0, 2.5, length(p - vec2(W * 0.5, H * 0.5)))) * 0.5);
	gasto *= 0.55 + 0.45 * noise(p * 1.7);
	c = mix(c, vec3(0.2, 0.16, 0.08), gasto * 0.55);
	float l = 0.0;
	if (p.x > -0.1 && p.x < W + 0.1 && p.y > -0.1 && p.y < H + 0.1) {
		l = max(l, line(p.x, lw)); l = max(l, line(p.x - W, lw)); l = max(l, line(p.y, lw)); l = max(l, line(p.y - H, lw));
		l = max(l, line(p.x - W * 0.5, lw));
		l = max(l, line(length(p - vec2(W * 0.5, H * 0.5)) - 9.15, lw));
		for (int s = 0; s < 2; s++) {
			float gx = s == 0 ? 0.0 : W, dir = s == 0 ? 1.0 : -1.0, rx = (p.x - gx) * dir;
			if (abs(p.y - H * 0.5) < 20.16 + 0.06) l = max(l, line(rx - 16.5, lw) * step(0.0, rx));
			if (rx > 0.0 && rx < 16.5) l = max(l, line(abs(p.y - H * 0.5) - 20.16, lw));
			if (abs(p.y - H * 0.5) < 9.16 + 0.06) l = max(l, line(rx - 5.5, lw) * step(0.0, rx));
			if (rx > 0.0 && rx < 5.5) l = max(l, line(abs(p.y - H * 0.5) - 9.16, lw));
			float dd = length(vec2(rx - 11.0, p.y - H * 0.5));
			if (rx > 16.5) l = max(l, line(dd - 9.15, lw));
			l = max(l, 1.0 - smoothstep(0.1, 0.14, length(vec2(rx - 11.0, p.y - H * 0.5))));
		}
		l = max(l, 1.0 - smoothstep(0.1, 0.14, length(p - vec2(W * 0.5, H * 0.5))));
	}
	ALBEDO = mix(c, vec3(0.78) * (0.92 + 0.08 * noise(p * 6.0)), l);
	ROUGHNESS = 0.92;
}
