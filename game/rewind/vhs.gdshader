shader_type canvas_item;
// VHS on a CRT. Bloom, CRT curve, vignette, scanlines, noise and the VHS smear are ported from
// Horri-Fi by Gizmo199 (MIT, https://github.com/Gizmo199/horri-fi). The rolling tracking band and
// chromatic aberration are driven by the game: `tracking` while rewinding and when a frame tears,
// `noise_amount` for static.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float noise_amount = 0.04;
uniform float aberration = 1.0;
uniform float tracking = 0.0;
uniform float bat_tracking = 0.0;
uniform float rewind_amount = 0.0;

uniform bool crt_curve_enabled = true;
// Horri-Fi curve: larger values are flatter.
uniform vec2 curve = vec2(7.0, 5.0);
// Horri-Fi bloom: radius in pixels, intensity, luminance threshold.
uniform vec3 bloom = vec3(6.0, 0.4, 0.45);
// Horri-Fi vignette: size, falloff.
uniform vec2 vignette = vec2(2.2, 0.22);
uniform float scan_strength = 0.12;
// Horri-Fi VHS smear, on top of what bad tracking adds.
uniform float vhs_strength = 0.03;

const float SAMPLES = 24.0;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 crt_curve(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	vec2 off = abs(uv) / curve;
	uv = uv + uv * off * off;
	return uv * 0.5 + 0.5;
}

// Spiral blur of only the bright pixels: candles, lanterns, the TV glow.
vec3 bloom_at(vec2 uv, vec2 texel) {
	float total = 0.0;
	float rad = 1.0;
	mat2 ang = mat2(vec2(0.73736882, -0.67549038), vec2(0.67549038, 0.73736882));
	vec2 point = normalize(fract(cos(uv * mat2(vec2(195.0, 174.0), vec2(286.0, 183.0))) * 742.0) - 0.5) * (bloom.x / sqrt(SAMPLES));
	vec3 amount = vec3(0.0);
	for (float i = 0.0; i < SAMPLES; i++) {
		point *= ang;
		rad += 1.0 / rad;
		vec3 s = texture(screen_tex, uv + point * (rad - 1.0) * texel).rgb;
		float lum = (s.r + s.g + s.b) / 3.0;
		amount += s * (1.0 / rad) * step(bloom.z, lum);
		total += 1.0 / rad;
	}
	return amount / total * bloom.y;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	if (crt_curve_enabled) {
		uv = crt_curve(uv);
	}
	float t = TIME;
	float line = floor(uv.y * 180.0);

	// Rolling tracking band and line jitter.
	float band_y = fract(t * 0.37);
	float band = smoothstep(0.08, 0.0, abs(uv.y - band_y)) * tracking;
	uv.x += band * (rand(vec2(line, floor(t * 30.0))) - 0.5) * 0.1;
	uv.x += (rand(vec2(line, floor(t * 24.0))) - 0.5) * 0.003 * (0.3 + tracking * 3.0);

	// Bat releases tear the camera vertically, across full-height columns.
	float column = floor(uv.x * 320.0);
	float band_x = fract(t * 0.61);
	float vertical_band = (1.0 - smoothstep(0.0, 0.11, abs(uv.x - band_x))) * bat_tracking;
	float column_jitter = rand(vec2(column, floor(t * 28.0))) - 0.5;
	uv.y += column_jitter * (vertical_band * 0.12 + bat_tracking * 0.006);

	vec2 px = vec2(SCREEN_PIXEL_SIZE.x * (aberration + tracking * 3.0), SCREEN_PIXEL_SIZE.y * vertical_band * 8.0);
	vec3 col = vec3(
		texture(screen_tex, uv + px).r,
		texture(screen_tex, uv).g,
		texture(screen_tex, uv - px).b);

	col += bloom_at(uv, SCREEN_PIXEL_SIZE);

	// VHS smear: a sideways-jittered copy bleeding in, worse when tracking is bad.
	vec2 smear = uv;
	smear.x += sin(t * rand(uv + fract(t))) * 0.01;
	col += texture(screen_tex, smear).rgb * (vhs_strength + tracking * 0.08);

	col *= (1.0 - scan_strength) + scan_strength * sin(uv.y * 360.0 * 3.14159);
	float n = rand(floor(uv * vec2(320.0, 180.0)) + fract(t * 7.0) * 100.0);
	col = mix(col, vec3(n), clamp(noise_amount + band * 0.4 + vertical_band * 0.35, 0.0, 1.0));
	col += vec3(0.06, 0.13, 0.16) * vertical_band;
	// Rewinding changes the recorded house while the kid holds position. A violet cast
	// distinguishes that state from ordinary PLAY and the cyan tracking glitches.
	col = mix(col, col * vec3(0.78, 0.72, 1.1) + vec3(0.02, 0.0, 0.045), rewind_amount * 0.38);

	vec2 v = uv * (1.0 - uv);
	col *= clamp(pow(v.x * v.y * vignette.x * 10.0, vignette.y), 0.0, 1.0);

	// Black outside the curved glass.
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		col = vec3(0.0);
	}
	COLOR = vec4(col, 1.0);
}
