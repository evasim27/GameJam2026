shader_type canvas_item;
// VHS look: chromatic aberration, scanlines, static noise and a rolling tracking band.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float noise_amount = 0.04;
uniform float aberration = 1.0;
uniform float tracking = 0.0;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;
	float line = floor(uv.y * 180.0);

	float band_y = fract(t * 0.37);
	float band = smoothstep(0.08, 0.0, abs(uv.y - band_y)) * tracking;
	uv.x += band * (rand(vec2(line, floor(t * 30.0))) - 0.5) * 0.1;
	uv.x += (rand(vec2(line, floor(t * 24.0))) - 0.5) * 0.003 * (0.3 + tracking * 3.0);

	vec2 px = vec2(SCREEN_PIXEL_SIZE.x * (aberration + tracking * 3.0), 0.0);
	vec3 col = vec3(
		texture(screen_tex, uv + px).r,
		texture(screen_tex, uv).g,
		texture(screen_tex, uv - px).b);

	col *= 0.88 + 0.12 * sin(uv.y * 360.0 * 3.14159);
	float n = rand(floor(uv * vec2(320.0, 180.0)) + fract(t * 7.0) * 100.0);
	col = mix(col, vec3(n), clamp(noise_amount + band * 0.4, 0.0, 1.0));
	vec2 d = uv - 0.5;
	col *= 1.0 - dot(d, d) * 0.8;
	COLOR = vec4(col, 1.0);
}
