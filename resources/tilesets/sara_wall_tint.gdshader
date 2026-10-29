shader_type canvas_item;

void fragment() {
	vec4 wall = texture(TEXTURE, UV);
	float brightness = dot(wall.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(0.20, 0.29, 0.39) * brightness, wall.a);
}
