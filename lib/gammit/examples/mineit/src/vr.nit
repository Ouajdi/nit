# This file is part of NIT (http://www.nitlanguage.org).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
module vr

import mineit
intrude import gammit::glesv2_display

redef class GammitApp
	redef fun frame_logic
	do
		super

		#
		display.vr_camera = camera
	end
end

redef class GammitDisplay

	#
	var vr_camera: nullable SimpleCamera = null

	# The aspect ration (in each eye) is half of the screen
	redef fun aspect_ratio do return super / 2.0

	# Distance between the eyes
	var eye_separation: Float = 0.03125/8.0

	redef fun draw_all_the_things
	do
		# If VR is not ready use standard implementation
		if vr_camera == null then
			super
			return
		end

		# Clear screen (same as in standard implementation)
		var back = background_color
		if back != null then
			gl.clear_color(back.r, back.g, back.b, back.a)
		end
		gl.clear((new GLBuffer).color.depth)

		# View matrix from head movement
		var center_projection = vr_camera.mvp_matrix

		# Left eye
		gl.viewport(0, 0, width/2, height)
		var projection_matrix = center_projection.copy
		projection_matrix.translate(-eye_separation, 0.0, 0.0)
		draw_all_the_things_core # Normal drawing

		# Right eye
		projection_matrix = center_projection.copy
		projection_matrix.translate(eye_separation, 0.0, 0.0)
		gl.viewport(width/2, 0, width/2, height)
		draw_all_the_things_core # Normal drawing

		# Mark selection result as dirty
		selection_calculated = false

		# Check for lingering errors
		assert_no_gl_error

		# We reset the viewport for selection
		gl.viewport(0, 0, width, height)
	end

	redef fun load_texture_from_pixels(pixels, width, height, has_alpha)
	do
		var texture = super

		# Set the minifying function to `linear` to avoid most of the flickering between eyes
		gl.tex_parameter_min_filter(new GLTextureTarget.flat, new GLTextureMinFilter.linear)

		return texture
	end
end
