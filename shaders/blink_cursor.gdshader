shader_type canvas_item;

uniform float speed : hint_range(0.0, 10.0) = 3.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.3;
uniform float max_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float blink = sin(TIME * speed) * 0.5 + 0.5;
	float alpha = mix(min_alpha, max_alpha, blink);
	COLOR = vec4(color.rgb, color.a * alpha);
}
