// applied on the UI
shader_type canvas_item;
// texture contains the final rendered image of the scene
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Creates a chromatic aberration effect used to distort

// number of color slices
uniform int levels = 3;
// magnitude of the slice offsets
uniform float spread = 0.01;

// Helper function
// chromatic slices calculated using color weights for each slice
vec3 chromatic_slice(float t){
    vec3 res = vec3(1.0-t, 1.0 - abs(t - 1.0), t - 1.0);
    return max(res, 0.0);
}

// combines the screen sampling, offset, and color weighting
void fragment(){
    vec3 sum = vec3(0);
    COLOR.rgb = vec3(0);
	// center offset calculation ensuring distortion pulls correctly away from the center of the screen
    vec2 offset = (UV - vec2(0.5))*vec2(1,-1);
	// iterates levels
    for(int i = 0; i < levels; i++){
        float t = 2.0*float(i)/float(levels-1); // range 0.0->2.0
        vec3 slice = vec3(1.0-t, 1.0 - abs(t - 1.0), t - 1.0);
        slice = max(slice, 0.0);
        sum += slice;
		// calculates the slice offset based on the slice and pulls it away from the screen in the colors direction
        vec2 slice_offset = (t-1.0)*spread*offset;
		// the screen is sampled at the new offset UV coordinate
		// The resulting color is weighted by the slice color vector and added to the final COLOR.rgb
		// The weights are also added to sum
        COLOR.rgb += slice * texture(SCREEN_TEXTURE, SCREEN_UV + slice_offset).rgb;
    }
    // normalize
	COLOR.rgb /= sum;
}