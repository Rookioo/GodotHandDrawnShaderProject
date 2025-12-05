// runs on 3D objects
shader_type spatial;
// will not react to late
render_mode unshaded;

// post processing shader to create an outline around objects

// final rendered color of the scene
uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;
// normal vectors for ever pixel
uniform sampler2D normal_texture : source_color, hint_normal_roughness_texture, filter_nearest;
// used to detect edges where objects are seperated
uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_nearest;
// the sensitivity of the depth edge detection
uniform float depth_treshold = 0.05;

// Helper functions
//
// returns the original color of the pixel from the screen texture
vec3 get_original(vec2 screen_uv)
{
	return texture(screen_texture, screen_uv).rgb;
}

// samples the normal texture and transformes the sampled color back into the normal values in the -1 to 1 range
vec3 get_normal(vec2 screen_uv)
{
	return texture(normal_texture, screen_uv).rgb * 2.0 - 1.0;
}

// samples the raw depth value and transforms the depth into the distance from the camera for consistent depth comparrisons
float get_depth(vec2 screen_uv, mat4 inv_projection_matrix)
{
	float depth = texture(depth_texture, screen_uv).r;
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= -view.w;
	return view.z;
}

void vertex() {
	// POSITION = vec4(VERTEX, 1.0);
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// where edge detection happens for every pixel on the screen
void fragment() {
	// SCREEN TEXTURE
	vec3 original = get_original(SCREEN_UV);

	// NORMAL
	vec3 normal = get_normal(SCREEN_UV);

	// DEPTH
	float depth = get_depth(SCREEN_UV, INV_PROJECTION_MATRIX);

	// GET SURROUNDING TEXEL
	// calculate the size of a single pixel then creates an array of UV coordinates for the 4 adjecent pixels
	vec2 texel_size = 2.0 / VIEWPORT_SIZE.xy;
	vec2 uvs[4]; // arrray containing the uvs of the surrounding pixel
	// up
	uvs[0] = vec2(SCREEN_UV.x, SCREEN_UV.y + texel_size.y );
	// down
	uvs[1] = vec2(SCREEN_UV.x, SCREEN_UV.y - texel_size.y );
	// left
	uvs[2] = vec2(SCREEN_UV.x + texel_size.x, SCREEN_UV.y);
	// right
	uvs[3] = vec2(SCREEN_UV.x - texel_size.x, SCREEN_UV.y);

	//EDGE DETECTION
	float depth_diff = 0.0;
	float normal_sum = 0.0;

	// loops through the 4 surrounding pixels comparing their properties to the current pixel's properties
	for (int i = 0; i < 4; i++)
	{
		// sums the real world depth between the current pixel and its neighbors
		float d = get_depth(uvs[i], INV_PROJECTION_MATRIX);
		depth_diff += depth - d;

		// calculates the difference between the current pixel's normal vector and the neighbor's
		vec3 n = get_normal(uvs[i]);
		vec3 normal_diff = normal - n;

		vec3 normal_edge_bias = vec3(1.0, 1.0, 1.0);
		float normal_bias_diff = dot(normal_diff, normal_edge_bias);
		float normal_indicator = smoothstep(-0.01, 0.01, normal_bias_diff);

		normal_sum += dot(normal_diff, normal_diff) * normal_indicator;
	}
	// final outline calculation
	float depth_edge = step(depth_treshold, depth_diff);
	float outline = depth_edge + normal_sum;

	//ALBEDO = vec3(depth_diff + normal_sum);
	ALBEDO = mix(original, vec3(0.0), outline);
}
