shader_type canvas_item;

uniform float blanco : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = COLOR;
	COLOR = vec4(mix(c.rgb, vec3(1.0), blanco), c.a);
}
