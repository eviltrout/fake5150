/*
Shader from Godot Shaders - the free shader library.
godotshaders.com/shader/VHS-and-CRT-monitor-effect

This shader is under CC0 license. Feel free to use, improve and 
change this shader according to your needs and consider sharing 
the modified result to godotshaders.com.

Note: Modified slightly by Robin "eviltrout" Ward for this demo's
purposes.
*/

shader_type spatial;
render_mode unshaded;
uniform sampler2D texture_albedo : hint_albedo;
uniform float scanlines_opacity : hint_range(0.0, 1.0) = 0.3;
uniform float scanlines_width : hint_range(0.0, 0.5) = 0.25;
uniform float grille_opacity : hint_range(0.0, 1.0) = 0.0;
uniform vec2 resolution = vec2(320.0, 200.0);
uniform float brightness = 1.0;
uniform float vignette_intensity = 0.4; // Size of the vignette, how far towards the middle it should go.
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float aberration : hint_range(-1.0, 1.0) = 0.01;

vec2 random(vec2 uv){
    uv = vec2( dot(uv, vec2(127.1,311.7) ),
               dot(uv, vec2(269.5,183.3) ) );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}
// Generate a Perlin noise used by the distortion effects
float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix( mix( dot( random(uv_index + vec2(0.0,0.0) ), uv_fract - vec2(0.0,0.0) ),
                     dot( random(uv_index + vec2(1.0,0.0) ), uv_fract - vec2(1.0,0.0) ), blur.x),
                mix( dot( random(uv_index + vec2(0.0,1.0) ), uv_fract - vec2(0.0,1.0) ),
                     dot( random(uv_index + vec2(1.0,1.0) ), uv_fract - vec2(1.0,1.0) ), blur.x), blur.y) * 0.5 + 0.5;
}

// Adds a vignette shadow to the edges of the image
float vignette(vec2 uv){
	uv *= 1.0 - uv.xy;
	float vignette = uv.x * uv.y * 15.0;
	return pow(vignette, vignette_intensity * vignette_opacity);
}


void fragment() {
	vec2 uv = UV;
	vec4 albedo_tex = texture(texture_albedo,uv);

	albedo_tex.r = texture(texture_albedo, UV + vec2(aberration, 0.0) * .1).r;
	albedo_tex.g = texture(texture_albedo, UV - vec2(aberration, 0.0) * .1).g;
	albedo_tex.b = texture(texture_albedo, UV).b;
	albedo_tex.a = 1.0;
		
	float r = albedo_tex.r;
	float g = albedo_tex.g;
	float b = albedo_tex.b;

	
	if (grille_opacity > 0.0) {		
		float g_r = smoothstep(0.85, 0.95, abs(sin(uv.x * (resolution.x * 3.14159265))));
		r = mix(r, r * g_r, grille_opacity);
		
		float g_g = smoothstep(0.85, 0.95, abs(sin(1.05 + uv.x * (resolution.x * 3.14159265))));
		g = mix(g, g * g_g, grille_opacity);
		
		float b_b = smoothstep(0.85, 0.95, abs(sin(2.1 + uv.x * (resolution.x * 3.14159265))));
		b = mix(b, b * b_b, grille_opacity);		
	}

	albedo_tex.r = clamp(r * brightness, 0.0, 1.0);
	albedo_tex.g = clamp(g * brightness, 0.0, 1.0);
	albedo_tex.b = clamp(b * brightness, 0.0, 1.0);

	float scanlines = 0.5;
	if (scanlines_opacity > 0.0)
	{
		// Same technique as above, create lines with sine and applying it to the texture. Smoothstep to allow setting the line size.
		scanlines = smoothstep(scanlines_width, scanlines_width + 0.5, abs(sin(uv.y * (resolution.y * 3.14159265))));
		albedo_tex.rgb = mix(albedo_tex.rgb, albedo_tex.rgb * vec3(scanlines), scanlines_opacity);
	}
				
	albedo_tex.rgb *= vignette(uv);
		
	ALBEDO = albedo_tex.rgb;
}
