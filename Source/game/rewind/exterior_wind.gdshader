shader_type canvas_item;

// Lift the dark facade and path while preserving the moon and warm doorway highlights.
uniform float shadow_gamma : hint_range(0.4, 1.0) = 0.68;

// Only the tree canopies at the edges sway. The house, street and trunks stay still.
void fragment() {
	float left_tree = 1.0 - smoothstep(0.05, 0.27, UV.x);
	float right_tree = smoothstep(0.88, 0.99, UV.x);
	float canopy = 1.0 - smoothstep(0.18, 0.82, UV.y);
	float sway = sin(TIME * 1.15 + UV.y * 8.0) * 1.2 + sin(TIME * 0.62 + UV.y * 15.0) * 0.35;
	vec2 sample_uv = UV + vec2(sway * (left_tree + right_tree) * canopy / 480.0, 0.0);
	COLOR = texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))) * COLOR;
	COLOR.rgb = pow(max(COLOR.rgb, vec3(0.0)), vec3(shadow_gamma));
}
