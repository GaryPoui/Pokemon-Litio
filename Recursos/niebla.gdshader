shader_type canvas_item;

uniform vec2 tam = vec2(256.0, 192.0);
uniform vec2 centro = vec2(128.0, 96.0);
uniform float radio = 38.0;
uniform float densidad = 1.0;
uniform float tiempo = 0.0;
uniform vec4 tono : source_color = vec4(0.78, 0.8, 0.86, 1.0);

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 p = floor(UV * tam) + 0.5;
	float d = length(p - centro);
	float a = 0.0;
	if (d >= radio + 6.0) {
		vec2 q = floor((p + vec2(tiempo * 4.0, tiempo * 1.5)) / 4.0);
		a = ruido(q / 6.0) > 0.55 ? 0.7 : 0.85;
	} else if (d >= radio) {
		a = 0.5;
	}
	COLOR = vec4(tono.rgb, a * densidad);
}
