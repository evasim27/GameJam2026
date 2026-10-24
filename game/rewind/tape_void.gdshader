shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float tape_time = 0.0;
uniform float front = -0.1;
uniform vec2 center = vec2(0.0, 0.6);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// Work in coarse game pixels, including the distortion and crumbling silhouette.
	vec2 uv = floor(UV * vec2(320.0, 180.0)) / vec2(320.0, 180.0);
	vec2 delta = (uv - center) * vec2(1.77778, 1.0);
	float radius = max(length(delta), 0.012);
	float angle = atan(delta.y, delta.x);
	float ripple = sin(angle * 7.0 - tape_time * 4.0 + radius * 25.0);
	float edge = front - 0.16 * pow(abs(uv.y - center.y), 0.65) + ripple * 0.018;
	float grain = hash(floor(uv * vec2(160.0, 90.0)) + floor(tape_time * 12.0));
	edge += (grain - 0.5) * 0.025;
	float swallowed = 1.0 - smoothstep(edge - 0.008, edge + 0.012, uv.x);
	float pull = (1.0 - smoothstep(0.0, 0.2, uv.x - edge)) * (1.0 - swallowed);
	float twist = pull * 0.32 / (1.0 + radius * 4.0);
	float c = cos(twist);
	float s = sin(twist);
	vec2 warped = mat2(vec2(c, s), vec2(-s, c)) * delta;
	warped *= 1.0 + pull * 0.3;
	vec2 sample_uv = center + warped / vec2(1.77778, 1.0);
	sample_uv.x += (grain - 0.5) * 0.025 * pull;
	vec3 picture = texture(screen_tex, clamp(sample_uv, vec2(0.001), vec2(0.999))).rgb;
	// Fragments shear off the room and spiral into an almost lightless core.
	float spiral = pow(max(0.0, sin(angle * 11.0 + log(radius) * 17.0 - tape_time * 5.0)), 14.0);
	float debris = step(0.88, grain) * pull * (0.3 + spiral);
	vec3 torn = picture * (1.0 - pull * 0.55) + vec3(0.07, 0.045, 0.06) * debris;
	vec3 core = vec3(0.004, 0.002, 0.006) * spiral;
	COLOR = vec4(mix(torn, core, swallowed), max(swallowed, pull));
}
