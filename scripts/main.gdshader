shader_type canvas_item;

uniform float time;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;

	// Simulate lightning noise using sine and fract
	float noise = fract(sin(dot(uv * time * 5.0, vec2(12.9898, 78.233))) * 43758.5453);
	noise = smoothstep(0.4, 1.0, noise); // sharpen

	// Apply flickering brightness
	COLOR = vec4(vec3(noise) * intensity, intensity);
}
