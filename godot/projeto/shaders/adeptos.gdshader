// Adeptos 3D nas bancadas (MultiMesh): cada um com a cor da sua camisola (INSTANCE_CUSTOM.rgb)
// e uma fase própria (INSTANCE_CUSTOM.a). Levantam-se e saltam com `festa`, abanam os braços com `protesto`.
shader_type spatial;
uniform float festa = 0.0;       // 0..1: golo, grande lance
uniform float protesto = 0.0;    // 0..1: decisão contestada
uniform float pressao = 0.3;
uniform float canto = 0.0;       // 0..1: a cantar (braços a bater o compasso)     // 0..1: quantos estão de pé e a mexer
varying vec3 cor;
varying float pele;
varying vec3 marca;
float hash(float n) { return fract(sin(n * 91.345) * 43758.5453); }
void vertex() {
	float ph = INSTANCE_CUSTOM.a * 100.0;
	float h1 = hash(ph), h2 = hash(ph + 7.1);
	cor = INSTANCE_CUSTOM.rgb;
	marca = vec3(UV.x, UV.y, UV2.x);
	pele = h2;
	bool braco = marca.r > 0.5;
	// de pé quando a pressão sobe (cada um com o seu limiar)
	float pe = step(h1, pressao * 0.8 + festa + canto * 0.5) * 0.22;
	float salto = festa * max(0.0, sin(TIME * (7.0 + 3.0 * h2) + ph)) * (0.18 + 0.2 * h1);
	float mexe = 0.02 * sin(TIME * (1.5 + h2) + ph);
	VERTEX.y += pe + salto + mexe;
	if (braco) {
		// braços para o ar na festa; a abanar no protesto
		float bate = canto * step(0.45, h1) * (0.55 + 0.45 * sin(TIME * 6.2832 + h2 * 0.6));
		float up = clamp(festa * 1.4 + protesto + bate, 0.0, 1.0) * step(0.25, h2);
		float sh = 1.05;
		float d = VERTEX.y - pe - salto - mexe - sh;
		VERTEX.y = mix(VERTEX.y, pe + salto + mexe + sh - d * 1.0, up);
		VERTEX.x += protesto * 0.08 * sin(TIME * 9.0 + ph) * up;
	}
}
void fragment() {
	vec3 skin = mix(vec3(0.93, 0.76, 0.62), vec3(0.36, 0.23, 0.15), pele * pele);
	bool cabeca = marca.g > 0.5, braco = marca.r > 0.5;
	vec3 c = cabeca ? skin : cor;
	if (braco && marca.b > 0.5) c = skin;    // mãos
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
