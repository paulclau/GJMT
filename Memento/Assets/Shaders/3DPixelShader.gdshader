shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled;

uniform vec2 target_resolution = vec2(320.0, 180.0);
uniform float colors_per_channel : hint_range(1.0, 64.0, 1.0) = 8.0;

uniform float depth_outline_strength : hint_range(0.0, 1.0, 0.1) = 0.8;
uniform float normal_outline_strength : hint_range(0.0, 2.0, 0.1) = 0.5;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest;

uniform bool is_perspective_camera = true;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 get_normal(vec2 uv) {
	return texture(normal_texture, uv).rgb;
}

float get_linear_depth(vec2 uv, mat4 inv_proj_mat) {
	float depth = texture(depth_texture, uv).r;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = inv_proj_mat * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

float depth_edge(float d_neighbor, float d_center, float clamp_min) {
	return clamp(d_neighbor - d_center, clamp_min, 1.0);
}

void fragment() {
	vec2 uv = floor(SCREEN_UV * target_resolution) / target_resolution;

	float raw_depth = texture(depth_texture, uv).r;

	// Skip outline processing where no geometry exists
	if (raw_depth >= 0.9999) {
		vec4 screen_col = texture(screen_texture, uv);
		ALBEDO = screen_col.rgb;
		ALPHA = 1.0;
	} else {

		vec2 uvs[5] = {
			uv,
			uv + vec2(0.0, 1.0) / target_resolution,
			uv - vec2(0.0, 1.0) / target_resolution,
			uv + vec2(1.0, 0.0) / target_resolution,
			uv - vec2(1.0, 0.0) / target_resolution
		};

		float dc = get_linear_depth(uvs[0], INV_PROJECTION_MATRIX);
		float du = get_linear_depth(uvs[1], INV_PROJECTION_MATRIX);
		float dd = get_linear_depth(uvs[2], INV_PROJECTION_MATRIX);
		float dl = get_linear_depth(uvs[3], INV_PROJECTION_MATRIX);
		float dr = get_linear_depth(uvs[4], INV_PROJECTION_MATRIX);

		float clamp_min = is_perspective_camera ? -1.0 : 0.0;

		float h_depth = depth_edge(dl, dc, clamp_min) + depth_edge(dr, dc, clamp_min);
		float v_depth = depth_edge(du, dc, clamp_min) + depth_edge(dd, dc, clamp_min);

		float h_outline = step(0.55, h_depth) * step(0.7, distance(dl, dr));
		float v_outline = step(0.55, v_depth) * step(0.7, distance(du, dd));
		float depth_outline = 1.0 - step(0.01, h_outline + v_outline) * depth_outline_strength;

		vec3 nc = get_normal(uvs[0]);
		vec3 nu = get_normal(uvs[1]);
		vec3 nd = get_normal(uvs[2]);
		vec3 nl = get_normal(uvs[3]);
		vec3 nr = get_normal(uvs[4]);

		float depth_fade_u = 1.0 - smoothstep(0.0, 1.0, abs(du - dc));
		float depth_fade_d = 1.0 - smoothstep(0.0, 1.0, abs(dd - dc));
		float depth_fade_l = 1.0 - smoothstep(0.0, 1.0, abs(dl - dc));
		float depth_fade_r = 1.0 - smoothstep(0.0, 1.0, abs(dr - dc));

		float nu_difference = distance(nc, nu) * depth_fade_u;
		float nd_difference = distance(nc, nd) * depth_fade_d;
		float nl_difference = distance(nc, nl) * depth_fade_l;
		float nr_difference = distance(nc, nr) * depth_fade_r;

		float h_inline = step(0.2, nl_difference + nr_difference);
		float v_inline = step(0.2, nu_difference + nd_difference);
		float normal_outline = step(0.1, h_inline + v_inline) * normal_outline_strength;

		vec4 screen_col = texture(screen_texture, uv);

		vec3 quantized_color =
			floor(screen_col.rgb * colors_per_channel)
			/ colors_per_channel;

		ALBEDO = quantized_color * depth_outline * (1.0 + normal_outline);
		ALPHA = 1.0;
	}
}