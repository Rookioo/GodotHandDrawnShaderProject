// runs on 3D objects
shader_type spatial;

// low-framerate, wobbly, living clay sculpture, shaded with hand-drawn cross-hatching lines in the shadowed areas

// scale of the displacement waves
uniform float size = 0.4;
// magnitude of the vertex displacement
uniform float intensity = 0.7;
// framerate of the animation
uniform float frame_time = 0.17;
// direction of the light source for the hatching
uniform vec3 light_direction = vec3(-0.483, 0.866, -0.129);

// hashing texture
uniform sampler2D hatch;
// base color of the object
uniform vec3 color: source_color;
// size of the hatches on the character
uniform float hatch_size = 1.0;

// handles the geometric distortion and is the source of the animation
void vertex() {
	// stepped time for distortion
	float rounded_time = round(TIME / frame_time) * frame_time;
		
	// vertex displacement
	// each axis is a combination of two waves moving along different axes for an organic/blobby movement
	// uses cos to create a periodic undulating shape (pow softens the wave peaks)
	float heightX = pow(abs(cos(VERTEX.y * size + rounded_time * 10.0)), 0.5) * intensity 
	 - pow(abs(cos(VERTEX.z * size * 0.7 + rounded_time * 5.0)), 0.5) * intensity * 1.3;          
	float heightY = pow(abs(cos(VERTEX.x * size + rounded_time * 15.0)), 0.5) * intensity 
	 - pow(abs(cos(VERTEX.z * size * 0.7 + rounded_time * 10.0)), 0.5) * intensity * 1.3;
	float heightZ = pow(abs(cos(VERTEX.y * size + rounded_time * 20.0)), 0.5) * intensity 
	 - pow(abs(cos(VERTEX.x * size * 0.7 + rounded_time * 15.0)), 0.5) * intensity * 1.3;
	VERTEX += vec3(heightX, heightY, heightZ);
}


// handles coloring and hatching based on the lighting
void fragment() {
	// same stepped time to be in sync with vertex
	float rounded_time = round(TIME / frame_time) * frame_time;
	
	// Normal transformation to compare with light direction
	mat3 view_to_world_normal_mat = mat3(
		INV_VIEW_MATRIX[0].xyz,
		INV_VIEW_MATRIX[1].xyz,
		INV_VIEW_MATRIX[2].xyz
	);
	
	// determine how much light a surface recieves
	float NdotL = dot(view_to_world_normal_mat * NORMAL , light_direction);
	float mask = 1.0;
	// applies hatching to areas that are not fully lit
	if (NdotL < 0.5) {
		mask *= texture(hatch, UV * hatch_size + rounded_time).r * 2.0 - 1.0; 
		mask = clamp(mask, 0.0, 1.0);
	} 
	// multiplies the mask by a second layer of hatching for deep shadows
	if (NdotL < 0.1) {
		mask *= texture(hatch, vec2(UV.x, -UV.y) * hatch_size + rounded_time).r * 2.0 - 1.0;
		mask = clamp(mask, 0.0, 1.0); 
	}
	// final color
	ALBEDO = mix(vec3(0.0), color, mask);
}


