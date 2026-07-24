shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D carve_mask : hint_default_black;
uniform float carve_threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	//Wherever the mask is "hot," we've carved through, just don't draw the fragment
	//The inner shell mesh sitting just behind this one shows through instead
	float carved = texture(carve_mask, UV).r;
	if (carved > carve_threshold) {
		discard;
	}

	ALBEDO = texture(albedo_texture, UV).rgb;
	ROUGHNESS = 0.8;
}