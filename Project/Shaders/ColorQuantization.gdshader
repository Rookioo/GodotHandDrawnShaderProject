// canvas item to be attatched to the player camera
shader_type canvas_item;

uniform bool shader_enabled = true;

// post processing filter to give the screen a retro, low-fidelity look by combining resolution scaleing, color quantization, and ordered dithering

uniform bool dithering = false;
// controls the magnitude of the dither pattern
uniform int dithering_size : hint_range(1, 16) = 2;
// factor by which to downscale the image resolution
uniform int resolution_scale : hint_range(1, 64) = 2;
// number of discrete color steps avalibe for each RGB color channel
uniform int quantization_level : hint_range(1, 64) = 16;

// the texture of the final rendered image of the screen
uniform sampler2D SCREEN_TEXTURE:hint_screen_texture,filter_linear;

// implements ordered dithering using a 4x4 matrix
int dithering_pattern(ivec2 fragcoord) {
  const int pattern[] = {
    -4, +0, -3, +1,
    +2, -2, +3, -1,
    -3, +1, +4, +0,
    +3, -1, +2, -2
  };
  int x = fragcoord.x % 4;
  int y = fragcoord.y % 4;
	// returns a small specific offset value
  return pattern[y * 4 + x] * dithering_size;
}

// Color quantization function to enforce a limited color palette on the image by posterizing colors
vec3 quantize_color(vec3 color, int levels) {
  if (levels <= 1) return vec3(0.0);
  float step = 1.0 / float(levels - 1);
  return round(color / step) * step;
}

// applies all 3 effects in sequence
// downsampling, dithering, and color quantization
void fragment() {
  vec4 final_color;

  if (!shader_enabled) {
    // If shader is disabled, output original screen texture color
    final_color = texture(SCREEN_TEXTURE, UV);
  } else {
    vec2 tex_size = vec2(textureSize(SCREEN_TEXTURE, 0));

    if (tex_size.x <= 0.0 || tex_size.y <= 0.0) {
      final_color = vec4(0.0);
    } else {
      // Calculate the scaled-down texture coordinate
      ivec2 texel_coord = ivec2(floor(UV * tex_size / float(resolution_scale)));

      // Sample the color from the screen texture at the scaled coordinate
      // Multiplying by resolution_scale ensures we sample the correct 'pixel' from the low-res grid.
      vec3 color = texelFetch(SCREEN_TEXTURE, texel_coord * resolution_scale, 0).rgb;

      // Apply optional Dithering
      if (dithering) {
        // Calculate the dither value based on the position in the low-res grid
        int dither = dithering_pattern(texel_coord);
        color += vec3(float(dither) / 255.0);
      }

      // Clamp the color and apply Quantization
      color = clamp(color, 0.0, 1.0);
      color = quantize_color(color, quantization_level);

      // Output the final processed color
      final_color = vec4(color, 1.0);
    }
  }

  COLOR = final_color;
}