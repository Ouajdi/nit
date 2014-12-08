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
	var vr_camera: SimpleCamera

	#display.projection_matrix = camera.mvp_matrix

	# The aspect ration (in each eye) is half of the screen
	redef fun aspect_ratio do return super / 2.0

	redef fun draw_all_the_things
	do
		# TODO tweak
		var eye_sep = 0.02

		var last_position = new Point3d[Float].from(vr_camera.position)

		vr_camera.move(-eye_sep/2.0, 0.0, 0.0)

		gl.viewport(0, 0, width/2, height)



		# from super

		var back = background_color
		if back != null then
			gl.clear_color(back.r, back.g, back.b, back.a)
		end

		gl.clear((new GLBuffer).color.depth)

		#================
		# dup

		var projection_matrix = vr_camera.mvp_matrix

		# XY double

		# TODO better iterators and cover null textures!
		for set in visibles.sets do
			var draw_mode = set.draw_mode
			var texture = set.gl_texture

			var program = set.program
			if program == null then program = default_program
			assert program isa DefaultGammitProgram
			program.use

			var total_vertices = 0
			if set.is_dirty then

				set.is_dirty = false

				var colors = new Array[Float]
				var translation = new Array[Float]
				var scale = new Array[Float]
				var vertices = new Array[Float]
				var tex_coords = new Array[Float]

				# Acumulate all entries into a vertex arrays
				# TODO use a VBO
				for entry in set do
					var n_vertices = entry.vertices.length / 3
					total_vertices += entry.vertices.length

					# Selection
					var c = entry.color.to_a
					colors.add_all c*n_vertices

					# Translation
					var t = [entry.x.to_f, entry.y.to_f, entry.z.to_f]
					translation.add_all t*n_vertices

					# Scale
					for i in n_vertices.times do scale.add entry.scale

					# Vertices
					vertices.add_all entry.vertices

					var coords_repeat = n_vertices / 6
					if texture == null then
						tex_coords.add_all(new Array[Float].filled_with(0.0, 6) * coords_repeat)
					else
						tex_coords.add_all(entry.texture.as(GammitGLTexture).coordinates * coords_repeat)
					end
				end

				# Prepare data for OpenGL ES
				var vertex = set.vertex(program.color, colors)
				program.color.array_pointer0(4, vertex)
				program.color.array_enabled = true

				vertex = set.vertex(program.translation, translation)
				program.translation.array_pointer0(3, vertex)
				program.translation.array_enabled = true

				vertex = set.vertex(program.scale, scale)
				program.scale.array_pointer0(1, vertex)
				program.scale.array_enabled = true

				vertex = set.vertex(program.position, vertices)
				program.position.array_pointer0(3, vertex)
				program.position.array_enabled = true

				vertex = set.vertex(program.texture_coordinates, tex_coords)
				program.texture_coordinates.array_pointer0(2, vertex)
				program.texture_coordinates.array_enabled = true
			else
				for entry in set do
					total_vertices += entry.vertices.length
				end

				var vertex = set.vertex_array(program.color)
				program.color.array_pointer0(4, vertex)
				program.color.array_enabled = true

				vertex = set.vertex_array(program.translation)
				program.translation.array_pointer0(3, vertex)
				program.translation.array_enabled = true

				vertex = set.vertex_array(program.scale)
				program.scale.array_pointer0(1, vertex)
				program.scale.array_enabled = true

				vertex = set.vertex_array(program.position)
				program.position.array_pointer0(3, vertex)
				program.position.array_enabled = true

				vertex = set.vertex_array(program.texture_coordinates)
				program.texture_coordinates.array_pointer0(2, vertex)
				program.texture_coordinates.array_enabled = true
			end

			program.use_texture.value = texture != null
			program.texture_coordinates.array_enabled = texture != null

			if texture != null then
				texture.active 0
				texture.bind
				program.texture.value = 0
			end

			if program isa GammitUIProgram then
				program.projection.value = program.mvp_matrix
			else
				program.projection.value = projection_matrix
			end

			program.draw(draw_mode, 0, total_vertices/3)

			assert_no_gl_error
		end

		# dup
		#================

		vr_camera.move(eye_sep, 0.0, 0.0)
		projection_matrix = vr_camera.mvp_matrix

		gl.viewport(width/2, 0, width/2, height)


		#=====
		# dup

		# TODO better iterators and cover null textures!
		for set in visibles.sets do
			var draw_mode = set.draw_mode
			var texture = set.gl_texture

			var program = set.program
			if program == null then program = default_program
			assert program isa DefaultGammitProgram
			program.use

			var total_vertices = 0
			if set.is_dirty then

				set.is_dirty = false

				var colors = new Array[Float]
				var translation = new Array[Float]
				var scale = new Array[Float]
				var vertices = new Array[Float]
				var tex_coords = new Array[Float]

				# Acumulate all entries into a vertex arrays
				# TODO use a VBO
				for entry in set do
					var n_vertices = entry.vertices.length / 3
					total_vertices += entry.vertices.length

					# Selection
					var c = entry.color.to_a
					colors.add_all c*n_vertices

					# Translation
					var t = [entry.x.to_f, entry.y.to_f, entry.z.to_f]
					translation.add_all t*n_vertices

					# Scale
					for i in n_vertices.times do scale.add entry.scale

					# Vertices
					vertices.add_all entry.vertices

					var coords_repeat = n_vertices / 6
					if texture == null then
						tex_coords.add_all(new Array[Float].filled_with(0.0, 6) * coords_repeat)
					else
						tex_coords.add_all(entry.texture.as(GammitGLTexture).coordinates * coords_repeat)
					end
				end

				# Prepare data for OpenGL ES
				var vertex = set.vertex(program.color, colors)
				program.color.array_pointer0(4, vertex)
				program.color.array_enabled = true

				vertex = set.vertex(program.translation, translation)
				program.translation.array_pointer0(3, vertex)
				program.translation.array_enabled = true

				vertex = set.vertex(program.scale, scale)
				program.scale.array_pointer0(1, vertex)
				program.scale.array_enabled = true

				vertex = set.vertex(program.position, vertices)
				program.position.array_pointer0(3, vertex)
				program.position.array_enabled = true

				vertex = set.vertex(program.texture_coordinates, tex_coords)
				program.texture_coordinates.array_pointer0(2, vertex)
				program.texture_coordinates.array_enabled = true
			else
				for entry in set do
					total_vertices += entry.vertices.length
				end

				var vertex = set.vertex_array(program.color)
				program.color.array_pointer0(4, vertex)
				program.color.array_enabled = true

				vertex = set.vertex_array(program.translation)
				program.translation.array_pointer0(3, vertex)
				program.translation.array_enabled = true

				vertex = set.vertex_array(program.scale)
				program.scale.array_pointer0(1, vertex)
				program.scale.array_enabled = true

				vertex = set.vertex_array(program.position)
				program.position.array_pointer0(3, vertex)
				program.position.array_enabled = true

				vertex = set.vertex_array(program.texture_coordinates)
				program.texture_coordinates.array_pointer0(2, vertex)
				program.texture_coordinates.array_enabled = true
			end

			program.use_texture.value = texture != null
			program.texture_coordinates.array_enabled = texture != null

			if texture != null then
				texture.active 0
				texture.bind
				program.texture.value = 0
			end

			if program isa GammitUIProgram then
				program.projection.value = program.mvp_matrix
			else
				program.projection.value = projection_matrix
			end

			program.draw(draw_mode, 0, total_vertices/3)

			assert_no_gl_error
		end

		# Make selection result as dirty
		selection_calculated = false

		# Check for lingering errors
		assert_no_gl_error
		vr_camera.position = last_position

		# dup
		#=============

		# We reset the viewport for selections
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
