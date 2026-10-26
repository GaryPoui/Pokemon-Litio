shader_type canvas_item;

uniform float fuerza : hint_range(0.0, 1.0) = 0.0;
uniform float sentido = 1.0;
uniform vec3 tono : source_color = vec3(1.0, 0.42, 0.24);
uniform float periodo = 8.0;
uniform float grosor = 2.0;
uniform float velocidad = 40.0;
uniform float tiempo = 0.0;

void fragment() {
	vec4 c = COLOR;
	if (fuerza > 0.0 && c.a > 0.0) {
		vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
		float u = abs(mod(px.x, periodo) - periodo * 0.5 + 0.5);
		float t = floor(tiempo * velocidad);
		float desfase = mod(floor(px.x / periodo), 2.0) * periodo * 0.5;
		float e = mod(px.y - sentido * u + sentido * t + desfase, periodo);
		float hueco = step(u, periodo * 0.5 - 1.0);
		float flecha = step(e, grosor - 0.5) * hueco;
		float estela = step(grosor - 0.5, e) * step(e, grosor + 0.5) * hueco;
		float k = fuerza * (0.22 + 0.62 * flecha + 0.3 * estela);
		c.rgb = mix(c.rgb, tono, clamp(k, 0.0, 1.0));
	}
	COLOR = c;
}
