# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2011-2014 Alexis Laferrière <alexis.laf@xymus.net>
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
module glesv2_display

private import more_collections

import glesv2

import abstract_display
import matrix_algebra

#
class GammitDisplay
	super Display

	redef type T: GammitGLTexture

	# Desired display width, and after `setup`, the real display width
	redef var width: Int

	# Desired display height, and after `setup`, the real display height
	redef var height: Int

	init do setup(width, height)

	#
	var default_program: GammitProgram is noinit

	#
	var selection_program: GammitSelectionProgram is noinit

	#
	var ui_program: GammitUIProgram is noinit

	#var projection_matrix = othro_matrix(0.0, width.to_f, height.to_f, 0.0, 0.0, 100.0)

	# TODO remove writable?
	var projection_matrix: Matrix[Float] is writable, noinit

	# Aspect ratio of the screen as `width` out of `height`
	fun aspect_ratio: Float do return width.to_f / height.to_f

	private var last_vertex_length: Int is noinit

	# Completely initialize and setup this `GammitDisplay` on the running platform
	#
	# This method is refined by the implementation by platform `gammit::linux`, `gammit::android`, etc.
	fun setup(window_width, window_height: Int) is abstract

	# Setup the GLES display
	#
	# Called by `setup` in the implementation by platform.
	fun setup_gles
	do
		## Framebuffer
		#var depthbuffer = new GLRenderbuffer
		#depthbuffer.gen
		#depthbuffer.bind
		#depthbuffer.storage(width, height)
		#depthbuffer.attach

		## Setup the default program
		var program: GammitProgram = new DefaultGammitProgram
		assert program.error == null else print program.error.to_s
		self.default_program = program

		## Setup the selection program
		program = new GammitSelectionProgram
		assert program.error == null else print program.error.to_s
		self.selection_program = program

		## Setup 
		var aspect_ratio = width.to_f / height.to_f
		var mvp_matrix = new Matrix[Float].orthogonal(-1.0*aspect_ratio, 1.0*aspect_ratio, 1.0, -1.0, -1.0, 1.0)
		program = new GammitUIProgram(mvp_matrix)
		assert program.error == null else print program.error.to_s
		self.ui_program = program

		# Configure GL

		# Activate blending
		gl.capabilities.blend.enable
		gl.blend_func(new GLBlendFactor.src_alpha, new GLBlendFactor.one_minus_src_alpha)

		# Activate depth
		gl.capabilities.depth_test.enable
		gl.depth_func(new GLDepthFunc.lequal)
		gl.depth_mask true

		#gl_depth_range(0.0, 1.0)
		#gl_clear_depth 1.0

		#var culling = new GLCap.cull_face
		#culling.enable

		# Set default view, an orthogonal projection where z is the depth
		#var aspect_ratio = width.to_f / height.to_f
		#ui_program.mvp_matrix = new Matrix[Float].orthogonal(-1.0*aspect_ratio, 1.0*aspect_ratio, 1.0, -1.0, -1.0, 1.0)

		# TODO use somewhere else
		#var polygon_offset_fill = new GLCap.polygon_offset_fill
		#polygon_offset_fill.enable
		#gl_polygon_offset(-1.0, -2.0)
	end

	# Close and clean up the GLES display
	fun close_gles
	do
		default_program.vertex_shader.delete
		default_program.fragment_shader.delete
		default_program.delete
	end

	# TODO hack
	fun check_lock_cursor do end

	redef fun add(e)
	do
		super

		visibles.add e
	end

	fun remove(e: Visible)
	do
		entries.remove e
		# TODO replace with super

		visibles.remove e
	end

	#
	var visibles = new VisibleVault

	# 1 draw per:
	# * Type (triangles, points, etc.)
	# * Texture (or texture set)
	# * Shader (ui, ...)
	redef fun draw_all_the_things
	do
		var back = background_color
		if back != null then
			gl.clear_color(back.r, back.g, back.b, back.a)
		end

		gl.clear((new GLBuffer).color.depth)

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

			assert gl.error.is_ok else print "OpenGL error: {gl.error}"

			program.draw(draw_mode, 0, total_vertices/3)

			assert gl.error.is_ok else print "OpenGL error: {gl.error}"
		end

		# Make selection result as dirty
		selection_calculated = false

		# Check for lingering errors
		assert gl.error.is_ok else print "OpenGL error: {gl.error}"
	end

	# TODO extract the next 4 props to a its own module
	private var selection_map = new HashMap[Int, Visible]

	private var selection_calculated = false

	# Get the element visible at `x`, `y`, if any
	#
	# This is implemented by drawing the screen using plain colors on each
	# `Selectable` objects and them reading the selected color.
	fun visible_at(x, y: Int): nullable Visible
	do
		if not selection_calculated then draw_selection_screen

		# invert y
		y = height - y

		var data = once new NativeCByteArray(4)
		gl.read_pixels(x, y, 1, 1, new GLPixelFormat.rgba, new GLPixelType.unsigned_byte, data)
		assert_no_gl_error

		# Reconstitute ID from pixel color
		var id = data[0] + data[1]*256 + data[2]*256*256

		# may be useful for debugging
		# print "{id} {data[0]} {data[1]} {data[2]}"

		# 0 is the background
		if id == 0 then return null

		# Wrongful selection?
		if not selection_map.keys.has(id) then
			print "Gammit warning: Wrongful selection {id}"
			return null
		end

		return selection_map[id]
	end

	# HACK
	var selection_camera: IPoint3d[Float] is noinit, writable

	private fun draw_selection_screen
	do
		selection_calculated = true
		var next_selection_id = 1
		selection_map.clear

		var program = selection_program
		program.use

		gl.clear_color(0.0, 0.0, 0.0, 1.0)
		gl.clear((new GLBuffer).color.depth)

		# Activate depth
		# TODO remove?
		gl.capabilities.depth_test.enable

		for set in visibles.sets do
			var draw_mode = set.draw_mode
			var texture = set.gl_texture

			var colors = new Array[Float]
			var translation = new Array[Float]
			var scale = new Array[Float]
			var vertices = new Array[Float]
			var tex_coords = new Array[Float]

			# Texture
			var texture_location = default_program.gl_program.uniform_location("vTex")
			assert_no_gl_error

			# 
			var projection_location = default_program.gl_program.uniform_location("projection")
			assert_no_gl_error

			# Acumulate all entries into a vertex arrays
			# TODO use a VBO
			for entry in set do if entry isa Selectable then # TODO move up selectable to VisibleMap

				# HACK!
				if (entry.x - selection_camera.x).to_f.abs > 5.0 or
				   (entry.y - selection_camera.y).to_f.abs > 5.0 or
				   (entry.z - selection_camera.z).to_f.abs > 5.0 then continue

				var n_vertices = entry.vertices.length / 3

				var id = next_selection_id
				selection_map[id] = entry
				next_selection_id += 1

				# Set color for selection EXTRACT
				# TODO more than 255 items!
				var p1 = id % 256
				var p2 = id % (256**2) / 256
				var p3 = id % (256**3) / 256**2
				var c = [p1.to_f/255.0, p2.to_f/255.0, p3.to_f/255.0, 1.0]
				colors.add_all c*n_vertices

				# Translation
				var t = [entry.x.to_f,entry.y.to_f, entry.z.to_f]
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
			var va_colors = new VertexArray(1, 4, colors)
			va_colors.attrib_pointer
			va_colors.enable

			var va_translation = new VertexArray(2, 3, translation)
			va_translation.attrib_pointer
			va_translation.enable

			var va_scale = new VertexArray(3, 1, scale)
			va_scale.attrib_pointer
			va_scale.enable

			var vertex_array = new VertexArray(0, 3, vertices)
			vertex_array.attrib_pointer
			vertex_array.enable

			var vertex_tex_coords = new VertexArray(4, 2, tex_coords)
			vertex_tex_coords.attrib_pointer
			vertex_tex_coords.enable

			program.use_texture.value = texture != null

			if texture != null then
				texture.active 0
				texture.bind
				var texture_uniform = new UniformInt1(texture_location, 0)
			end

			var projection_uniform = new UniformMatrix4(projection_location, projection_matrix)

			vertex_array.draw_arrays_triangles(0, vertices.length/3)
			assert_no_gl_error
		end
	end

	redef fun load_texture_from_pixels(pixels, width, height, has_alpha)
	do
		var gl_tex = new GLTexture
		gl_tex.gen
		gl_tex.bind

		gl_tex_image2d(width, height, pixels, has_alpha)

		gl.tex_parameter_min_filter(new GLTextureTarget.flat, new GLTextureMinFilter.linear_mipmap_linear)
		gl.tex_parameter_mag_filter(new GLTextureTarget.flat, new GLTextureMagFilter.nearest)

		gl.tex_parameter_wrap_s(new GLTextureTarget.flat, new GLTextureWrap.mirrored_repeat)
		gl.tex_parameter_wrap_t(new GLTextureTarget.flat, new GLTextureWrap.mirrored_repeat)

		gl.hint_generate_mipmap(new GLHintMode.nicest)
		gl.generate_mipmap(new GLTextureTarget.flat)

		assert_no_gl_error

		return new GammitGLTexture(gl_tex, width, height)
	end

	# Is the cursor locked et the center of the screen?
	var lock_cursor = false is writable

	# Is the cursor visible?
	#
	# Only affects the desktop implementations.
	var show_cursor: Bool = true is writable
end

class GammitGLTexture
	super Texture

	var gl_texture: GLTexture

	var width: Int
	var height: Int

	var coordinates: Array[Float] = [0.0, 0.0,
			                         0.0, 1.0,
			                         1.0, 1.0,
			                         0.0, 0.0,
			                         1.0, 1.0,
			                         1.0, 0.0]

	redef fun subtexture(l, t, w, h)
	do
		var lf = l.to_f
		var tf = t.to_f
		var wf = w.to_f
		var hf = h.to_f

		return subtexture_by_sides(lf/width.to_f, tf/height.to_f,
		                    (lf+wf)/width.to_f, (tf+hf)/height.to_f)
	end

	# Get a subtexture by the coordinates of each sides
	fun subtexture_by_sides(l, t, r, b: Float): Subtexture
	do
		var tex = new Subtexture(gl_texture, width, height, l, t, r, b)
		tex.coordinates = [l, t,
			               l, b,
			               r, b,
			               l, t,
			               r, b,
			               r, t]
		return tex
	end
end

class Subtexture
	super GammitGLTexture

	var source_left: Float
	var source_top: Float
	var source_right: Float
	var source_bottom: Float
end

# Gammit shader
abstract class GammitShader

	# Implementation notes
	#
	# * Cannot be finalizable since it can reside only in GPU.
	# * TODO add alternatives to use shaders from binaries

	private var gl_shader: GLShader is noinit

	# Latest error raised by operations of this shader
	var error: nullable Error = null

	# Source code of this shader
	var source: Text

	# Build the shader according to its low-level type
	private fun build_gl_shader: GLShader is abstract

	init
	do
		# Create
		var gl_shader = build_gl_shader
		if not gl_shader.is_ok then
			self.error = new Error("Shader creation failed: {gl.error}")
			return
		end
		self.gl_shader = gl_shader

		gl_shader.source = source.to_cstring

		# Compile
		gl_shader.compile
		if not gl_shader.is_compiled then
			self.error = new Error("Shader compilation failed: {gl_shader.info_log}")
			return
		end

		error = gammit_gl_error
	end

	# Has this shader been deleted?
	var deleted = false

	# Delete this shader and free its resources, if it has not been deleted already
	fun delete do if not deleted then
		gl_shader.delete
		deleted = true
	end
end

# A Gammit vertex shader
class GammitVertexShader
	super GammitShader

	redef fun build_gl_shader do return new GLVertexShader
end

# A Gammit fragment shader
class GammitFragmentShader
	super GammitShader

	redef fun build_gl_shader do return new GLFragmentShader
end

private fun gammit_gl_error: nullable Error
do
	var gl_error = gl.error
	if gl_error.is_ok then return null
	return new Error("GL error: {gl_error}")
end

redef class Sys
	# `GammitProgram` currently in use, the latest receiver of `GammitProgram::use`
	var program_in_use: nullable GammitProgram = null
end

# An `Uniform` or an `Attribute` of a `GammitProgram`
abstract class Variable

	# The `GammitProgram` to which `self` belongs
	var program: GammitProgram

	# Name of `self` in the `program` source
	var name: String

	# Location of `self` in the compiled `program`
	var location: Int

	# Number of elements in this array (1 for variables, more for arrays)
	var size: Int

	# Is `self` an active uniform or attribute in the `program`? (if not, it may have been optimized out)
	fun is_active: Bool do return true
end

# An inactive shader variable the is either non-existant or has been optimized out
abstract class InactiveVariable
	super Variable

	redef fun is_active do return false
end

# A shader attribute
#
# It will use either the `constant` value or the data at `array_pointer` if
# and only if `array_enabled`.
class Attribute
	super Variable

	private var array_enabled_cache = false

	# Is the array attribute enabled? Otherwise it will use the constant.
	fun array_enabled: Bool do return array_enabled_cache

	# Set wether to use the data at `array_pointer` over `constant`.
	fun array_enabled=(value: Bool)
	do
		if not is_active then return

		program.use

		self.array_enabled_cache = value
		if value then
			location.enable_vertex_attrib_array
		else location.disable_vertex_attrib_array
	end

	fun array_pointer0(data_per_vertex: Int, array: GLfloatArray)
	do
		location.vertex_attrib_pointer(data_per_vertex, array.native_array)
	end

	fun array_pointer(data_per_vertex: Int, array: Array[Float])
	do
		if not is_active then return

		var native = native_float_array
		if native == null or array.length > native.length then
			if native != null then native.destroy
			native = new GLfloatArray.from(array)
			self.native_float_array = native
		else
			native.fill_from(array)
		end

		location.vertex_attrib_pointer(data_per_vertex, native.native_array)
	end

	private var native_float_array: nullable GLfloatArray = null

	# TODO check is active everywhere
	fun constant=(x, y, z, w: Float) do location.vertex_attrib4f(x, y, z, w)
end

class AttributeFloatVec2
	super Attribute
end

class AttributeFloatVec4
	super Attribute
end

class AttributeFloat
	super Attribute

	#redef type E: Float
	#redef fun value=(val)
end

class InactiveAttribute
	super InactiveVariable
	super AttributeFloatVec2
	super AttributeFloatVec4
	super AttributeFloat

	# TODO init private
end

#interface FloatData
#end

#redef universal Float super FloatData end
#redef class Matrix

# TODO make abstract
class Uniform
	super Variable

	private fun uniform_1i(index, x: Int) `{ glUniform1i(index, x); `}
end

class UniformBool
	super Uniform

	fun value=(val: Bool) do uniform_1i(location, if val then 1 else 0)
end

class UniformSampler2D
	super Uniform

	fun value=(val: Int) do uniform_1i(location, val)
end

class UniformFloatMat4
	super Uniform

	private var native_matrix_cache: nullable NativeGLfloatMatrix = null

	fun value=(matrix: Matrix[Float])
	do
		var native = native_matrix_cache
		if native == null then
			native = new NativeGLfloatMatrix.alloc
			self.native_matrix_cache = native
		end

		matrix.fill_native(native)
		uniform_matrix_4f(location, 1, false, native)
	end

	private fun uniform_matrix_4f(index, count: Int, transpose: Bool, data: NativeGLfloatMatrix) `{
		glUniformMatrix4fv(index, count, transpose, data);
	`}
end

# An `Uniform` that does not exist or that has been optimized out
#
# Returned by `GammitProgram::uniforms[]` when the uniform has not been
# identified as active by the driver. Operations on this class will have
# no effect.
#
# Act as a compatiliby when a program execpt a uniform to exist even in
# a context where the driver's compiler may have optimized it out. You
# must be careful when receiving a `InactiveUniform` as it may also
# silence real program errors.
class InactiveUniform
	super InactiveVariable
	super UniformBool
	super UniformSampler2D
	super UniformFloatMat4

	# TODO init private

	redef fun is_active do return false
end

#
#abstract class GammitProgram
redef class GammitProgram
	private var gl_program: GLProgram is noinit

	var error: nullable Error = null is protected writable

	var vertex_shader: GammitVertexShader is noinit

	var fragment_shader: GammitFragmentShader is noinit

	protected fun from_source(vertex_shader_source, fragment_shader_source: Text)
	do
		# vertex shader
		vertex_shader = new GammitVertexShader(vertex_shader_source)
		var error = vertex_shader.error
		if error != null then
			self.error = error
			return
		end

		# fragment shader
		fragment_shader = new GammitFragmentShader(fragment_shader_source)
		error = fragment_shader.error
		if error != null then
			self.error = error
			return
		end
	end

	init
	do
		var gl_program = new GLProgram
		if not gl_program.is_ok then
			self.error = new Error("Program creation failed: {gl.error.to_s}")
			return
		end
		self.gl_program = gl_program

		# The shaders should not have errors at this point, still, to be safe,
		# we move any error to the program error.

		# Vertex shader
		var vertex_shader = vertex_shader
		if vertex_shader.error != null then
			self.error = vertex_shader.error
			return
		end

		# Fragment shader
		var fragment_shader = fragment_shader
		if fragment_shader.error != null then
			self.error = fragment_shader.error
			return
		end

		# Attach shaders
		gl_program.attach_shader vertex_shader.gl_shader
		gl_program.attach_shader fragment_shader.gl_shader

		# Bind attribs
		# This is a dup from the source
		# TODO use this instead of es 300 shaders
		gl_program.bind_attrib_location(0, "vPosition")

		# Catch any errors up to here
		var error = gammit_gl_error
		if error != null then
			self.error = error
			return
		end

		# Link
		gl_program.link
		if not gl_program.is_linked then
			self.error = new Error("Linking failed: {gl_program.info_log}")
			return
		end

		# Fill the attribute and uniform lists
		var n_attribs = gl_program.n_active_attributes
		for a in [0..n_attribs[ do
			var name = gl_program.active_attrib_name(a)
			var size = gl_program.active_attrib_size(a)
			var typ = gl_program.active_attrib_type(a)
			var location = gl_program.attrib_location(name)

			# TODO select type from size and typ
			var attribute
			if typ.is_float then
				attribute = new AttributeFloat(self, name, location, size)
			else if typ.is_float_vec2 then
				attribute = new AttributeFloatVec2(self, name, location, size)
			else if typ.is_float_vec4 then
				attribute = new AttributeFloatVec4(self, name, location, size)
			else
				attribute = new Attribute(self, name, location, size)
			end
			attributes[name] = attribute
		end

		var n_uniforms = gl_program.n_active_uniforms
		for a in [0..n_uniforms[ do
			var name = gl_program.active_uniform_name(a)
			var size = gl_program.active_uniform_size(a)
			var typ = gl_program.active_uniform_type(a)
			var location = gl_program.uniform_location(name)

			var uniform
			if typ.is_bool then
				uniform = new UniformBool(self, name, location, size)
			else if typ.is_sampler_2d then
				uniform = new UniformSampler2D(self, name, location, size)
			else if typ.is_float_mat4 then
				uniform = new UniformFloatMat4(self, name, location, size)
			else
			# TODO more types
				uniform = new Uniform(self, name, location, size)
			end
			uniforms[name] = uniform
		end
	end

	# Attributes in this program organized by name
	#
	# Active attributes are gathered at the construction of `self`.
	# Upon request, inactive attributes are returned as an `InactiveAttribute`.
	var attributes: Map[String, Attribute] =
		new DefaultMap[String, Attribute](new InactiveAttribute(self, "", -1, 0))

	#
	var uniforms: Map[String, Uniform] =
		new DefaultMap[String, Uniform](new InactiveUniform(self, "", -1, 0))

	# Notify the GPU to use this program
	fun use
	do
		assert error == null
		if sys.program_in_use != self then
			gl_program.use
			sys.program_in_use = self
		end
	end

	#
	fun draw(draw: GLDrawMode, from, to: Int)
	do
		gl.draw_arrays(new GLDrawMode.triangles, from, to)
	end

	# Has this program been deleted?
	var deleted = false

	# Delete this program if it has not already been deleted
	fun delete
	do
		if not deleted then
			gl_program.delete
			deleted = true
		end
	end
end

class DefaultGammitProgram
	super GammitProgram

	#
	init
	do
		from_source(vertex_shader_source, fragment_shader_source)
		super
	end

	#
	fun vertex_shader_source: String do return """
		attribute vec4  position;
		attribute vec4  color;
		attribute vec4  translation;
		attribute float scale;
		attribute vec2  texCoord;

		uniform  mat4 projection;

		varying vec4 v_color;
		varying vec2 v_texCoord;

		void main()
		{
		  v_color = color;
		  gl_Position = (vec4(position.xyz * scale, 1.0) + translation) * projection;
		  v_texCoord = texCoord;
		}
		""" @ glsl_vertex_shader

	# Position of each vertex
	fun position: AttributeFloatVec4 is lazy do return attributes["position"].as(AttributeFloatVec4)

	# Color of each vertex
	fun color: AttributeFloatVec4 is lazy do return attributes["color"].as(AttributeFloatVec4)

	# Translation to apply to each vertex
	fun translation: AttributeFloatVec4 is lazy do return attributes["translation"].as(AttributeFloatVec4)

	# Scale to apply to each vertex
	fun scale: AttributeFloat is lazy do return attributes["scale"].as(AttributeFloat)

	# Texture coordinate of each vertex
	fun texture_coordinates: AttributeFloatVec2 is lazy do return attributes["texCoord"].as(AttributeFloatVec2)

	# 
	fun projection: UniformFloatMat4 is lazy do return uniforms["projection"].as(UniformFloatMat4)

	#
	fun fragment_shader_source: String do return """
		precision mediump float;

		varying vec4 v_color;
		varying vec2 v_texCoord;

		uniform sampler2D vTex;
		uniform bool use_texture;

		//out vec4 outColor;

		void main()
		{
			if(use_texture) {
				//outColor = v_color * texture(vTex, v_texCoord);
				gl_FragColor = v_color * texture2D(vTex, v_texCoord);
				if(gl_FragColor.a < 0.1) discard;
			} else {
				//outColor = v_color;
				gl_FragColor = v_color;
			}
			//gl_FragColor = v_color * v_texCoord.x;
		}
		""" @ glsl_fragment_shader

	#
	fun texture: UniformSampler2D is lazy do return uniforms["vTex"].as(UniformSampler2D)

	fun use_texture: UniformBool is lazy do return uniforms["use_texture"].as(UniformBool)
end

class GammitSelectionProgram
	super GammitProgram

	#
	init
	do
		from_source(vertex_shader_source, fragment_shader_source)
		super
	end

	#
	var vertex_shader_source = """
		#version 300 es
		layout(location = 0) in vec4 vPosition;
		layout(location = 1) in vec4 vId;
		layout(location = 2) in vec4 vTranslation;
		layout(location = 3) in float vScale;
		layout(location = 4) in vec2 vTexCoord;
		uniform mat4 projection;
		out vec4 v_color;
		out vec2 v_texCoord;
		void main()
		{
		  v_color = vId;
		  gl_Position = (vPosition * vScale + vTranslation) * projection;
		  v_texCoord = vTexCoord;
		}
		""" @ glsl_vertex_shader

	#
	var fragment_shader_source = """
		#version 300 es
		precision mediump float;

		in vec4 v_color;
		in vec2 v_texCoord;

		uniform sampler2D vTex;
		uniform bool use_texture;

		layout(location = 0) out vec4 outColor;

		void main()
		{
			outColor.rgb = v_color.rgb;
			if(use_texture) {
				outColor.a = roundEven(texture(vTex, v_texCoord).a);
			} else {
				outColor.a = 1.0;
			}
		}
		""" @ glsl_fragment_shader

	fun use_texture: UniformBool is lazy do return uniforms["use_texture"].as(UniformBool)
end

class GammitUIProgram
	super DefaultGammitProgram

	var mvp_matrix: Matrix[Float] is writable

	#
	init
	do
		from_source(vertex_shader_source, fragment_shader_source)
		super
	end

	#
	redef var vertex_shader_source = """
		attribute vec4  position;
		attribute vec4  color;
		attribute vec4  translation;
		attribute float scale;
		attribute vec2  texCoord;

		uniform  mat4 projection;

		varying vec4 v_color;
		varying vec2 v_texCoord;

		void main()
		{
		  v_color = color;
		  gl_Position = (vec4(position.xyz * scale, 1.0) + translation) * projection;
		  v_texCoord = texCoord;
		}
		""" @ glsl_vertex_shader

	#
	redef var fragment_shader_source = """
		precision mediump float;

		varying vec4 v_color;
		varying vec2 v_texCoord;

		uniform sampler2D vTex;
		uniform bool use_texture;

		void main()
		{
			if(use_texture) {
				//outColor = v_color * texture(vTex, v_texCoord);
				gl_FragColor = v_color * texture2D(vTex, v_texCoord);
				if(gl_FragColor.a < 0.1) discard;
			} else {
				//outColor = v_color;
				gl_FragColor = v_color;
			}
			//gl_FragColor = v_color * v_texCoord.x;
		}
		""" @ glsl_fragment_shader
end

class Vector
	super Point3d[Float]
end

# An optimized collection of `Visible` sorting them by
# * program
# * draw mode
# * texture
class VisibleVault

	private var sets = new Array[VisibleSet]

	private fun set_for(e: Visible, create_set: Bool): nullable VisibleSet
	do
		var draw_mode = e.draw_mode
		var gammit_texture = e.texture
		assert gammit_texture isa nullable GammitGLTexture

		var gl_texture
		if gammit_texture == null then
			gl_texture = null
		else gl_texture = gammit_texture.gl_texture

		# TODO use nested hash map if this ever becomes performance critical
		for set in sets do
			if set.draw_mode == draw_mode and
			   set.gl_texture == gl_texture and
			   set.program == e.program then
				return set
			end
		end

		if not create_set then return null

		var set = new VisibleSet(draw_mode, gl_texture, e.program)
		sets.add set
		return set
	end

	# Add `e` to the collection
	fun add(e: Visible)
	do
		var set = set_for(e, true)
		set.add e
	end

	# Remove `e` from the collection
	fun remove(e: Visible)
	do
		var set = set_for(e, false)
		assert set != null
		set.remove e
		if set.is_empty then sets.remove set
	end

	# Does `self` has `e`?
	fun has(e: Visible): Bool
	do
		var set = set_for(e, false)
		return set != null and set.has(e)
	end

	fun clear
	do
		# TODO free some memory?
		sets.clear
	end
end

class VisibleSet
	super HashSet[Visible]

	var is_dirty = false

	var draw_mode: GLDrawMode
	var gl_texture: nullable GLTexture
	var program: nullable GammitProgram

	private var vertex_cache = new Map[Attribute, GLfloatArray]

	# Get vertex cache
	#
	# RENAME
	fun vertex(attribute: Attribute, array: Array[Float]): GLfloatArray
	do
		var cache
		if vertex_cache.keys.has(attribute) then
			cache = vertex_cache[attribute]
			if cache.length < array.length then
				cache.destroy
				cache = null
			end
		else cache = null

		if cache == null then
			cache = new GLfloatArray(array.length) # TODO add some room to grow?
			vertex_cache[attribute] = cache
		end

		cache.fill_from(array)

		return cache
	end

	# Rename
	fun vertex_array(attribute: Attribute): GLfloatArray
	do
		assert vertex_cache.keys.has(attribute)
		return vertex_cache[attribute]
	end

	redef fun add(e)
	do
		is_dirty = true
		super
	end

	redef fun remove(e)
	do
		is_dirty = true
		super
	end

	redef fun to_s do return "<Set {gl_texture or else "no texture"} {is_dirty}>"
end

private class GCVertex
	var positions = new HashMap[Attribute, Memory]

	#
	var free_positions = new MultiHashMap[Int, Memory]

	fun defragment is abstract

	fun used_memory_segments: Array[Memory] is abstract
end

private class Memory
	var start: Int
	var lenght: Int
end
