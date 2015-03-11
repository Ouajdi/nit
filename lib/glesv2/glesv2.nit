# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# OpenGL graphics rendering library for embedded systems, version 2.0
#
# This is a low-level wrapper, it can be useful for developers already familiar
# with the C API of OpenGL. Most developers will prefer to use higher level
# wrappers such as `mnit` and `gammit`.
#
# Defines the annotations `glsl_vertex_shader` and `glsl_fragment_shader`
# applicable on string literals to check shader code using `glslangValidator`.
# The tool must be in PATH. It can be downloaded from
# https://www.khronos.org/opengles/sdk/tools/Reference-Compiler/
#
# # API structure
#
# Services offered by this module aims to be close to the C API while
# preserving a style compatible with the Nit language.
#
# * `gl` prefixed functions of the C API are replaced by methods of the same
# name, without the prefix, in snake case, accessible within the utility object
# at `gl`.
#
#     Example: `glDrawTriangles` becomes `gl.draw_triangles`
#
# * Instances of `GLEnum` are represented by a set of classes prefixed by `GL`,
# subclasses to the Nit class `GLEnum`. The Nit class represent the category
# or the user method, named constructors access specific intances of the
# enumeration.
#
#     Example: `GL_CLAMP_TO_EDGE` becomes `new GLTextureWrap::clamp_to_edge`
#
# * Some creative naming is applied when the name resulting from previous
# conversions is not supported in Nit.
#
#     Example: `GL_TEXTURE_2D` becomes `new GLTextureTarget.flat`
#
# * Many precise methods for the same C function where different arguments
# imply different argument types. Better static typing.
#
# # External links
#
# Most services of this module are a direct wrapper of the underlying
# C library. If a method or class is not documented in Nit, refer to
# the official documentation by the Khronos Group at:
# http://www.khronos.org/opengles/sdk/docs/man/
module glesv2 is
	pkgconfig
	new_annotation glsl_vertex_shader
	new_annotation glsl_fragment_shader
	ldflags("-lGLESv2")@android
end

import android::aware
intrude import c
import matrix

in "C Header" `{
	#include <GLES2/gl2.h>
`}

# OpenGL ES program to which we attach shaders
extern class GLProgram `{GLuint`}
	# Create a new program
	#
	# The newly created instance should be checked using `is_ok`.
	new `{ return glCreateProgram(); `}

	# Is this a valid program?
	fun is_ok: Bool `{ return glIsProgram(recv); `}

	# Attach a `shader` to this program
	fun attach_shader(shader: GLShader) `{ glAttachShader(recv, shader); `}

	# Set the location for the attribute by `name`
	fun bind_attrib_location(index: Int, name: String) import String.to_cstring `{
		GLchar *c_name = String_to_cstring(name);
		glBindAttribLocation(recv, index, c_name);
	`}

	# Get the location of the attribute by `name`
	#
	# Returns `-1` if there is no active attribute named `name`.
	fun attrib_location(name: String): Int import String.to_cstring `{
		GLchar *c_name = String_to_cstring(name);
		return glGetAttribLocation(recv, c_name);
	`}

	# Get the location of the uniform by `name`
	#
	# Returns `-1` if there is no active uniform named `name`.
	fun uniform_location(name: String): Int import String.to_cstring `{
		GLchar *c_name = String_to_cstring(name);
		return glGetUniformLocation(recv, c_name);
	`}

	# Query information on this program
	fun query(pname: Int): Int `{
		int val;
		glGetProgramiv(recv, pname, &val);
		return val;
	`}

	# Try to link this program
	#
	# Check result using `in_linked` and `info_log`.
	fun link `{ glLinkProgram(recv); `}

	# Is this program linked?
	fun is_linked: Bool do return query(0x8B82) != 0

	# Use this program for the following operations
	fun use `{ glUseProgram(recv); `}

	# Delete this program
	fun delete `{ glDeleteProgram(recv); `}

	# Has this program been deleted?
	fun is_deleted: Bool do return query(0x8B80) != 0

	# Validate whether this program can be executed in the current OpenGL state
	#
	# Check results using `is_validated` and `info_log`.
	fun validate `{ glValidateProgram(recv); `}

	# Boolean result of `validate`, must be called after `validate`
	fun is_validated: Bool do return query(0x8B83) != 0

	# Retrieve the information log of this program
	#
	# Useful with `link` and `validate`
	fun info_log: String import NativeString.to_s `{
		int size;
		glGetProgramiv(recv, GL_INFO_LOG_LENGTH, &size);
		GLchar *msg = malloc(size);
		glGetProgramInfoLog(recv, size, NULL, msg);
		return NativeString_to_s(msg);
	`}

	# Number of active uniform in this program
	#
	# This should be the number of uniforms declared in all shader, except
	# unused uniforms which may have been optimized out.
	fun n_active_uniforms: Int do return query(0x8B86)

	# Length of the longest uniform name in this program, including `\n`
	fun active_uniform_max_length: Int do return query(0x8B87)

	# Number of active attributes in this program
	#
	# This should be the number of uniforms declared in all shader, except
	# unused uniforms which may have been optimized out.
	fun n_active_attributes: Int do return query(0x8B89)

	# Length of the longest uniform name in this program, including `\n`
	fun active_attribute_max_length: Int do return query(0x8B8A)

	# Number of shaders attached to this program
	fun n_attached_shaders: Int do return query(0x8B85)

	# Name of the active attribute at `index`
	fun active_attrib_name(index: Int): String
	do
		var max_size = active_attribute_max_length
		return active_attrib_name_native(index, max_size).to_s
	end
	private fun active_attrib_name_native(index, max_size: Int): NativeString `{
		// We get more values than we need, for compatibility. At least the
		// NVidia driver tries to fill them even if NULL.

		char *name = malloc(max_size);
		int size;
		GLenum type;
		glGetActiveAttrib(recv, index, max_size, NULL, &size, &type, name);
		return name;
	`}

	# Size of the active attribute at `index`
	fun active_attrib_size(index: Int): Int `{
		int size;
		GLenum type;
		glGetActiveAttrib(recv, index, 0, NULL, &size, &type, NULL);
		return size;
	`}

	# Type of the active attribute at `index`
	#
	# May only be float related data types (single float, vectors and matrix).
	fun active_attrib_type(index: Int): GLFloatDataType `{
		int size;
		GLenum type;
		glGetActiveAttrib(recv, index, 0, NULL, &size, &type, NULL);
		return type;
	`}

	# Name of the active uniform at `index`
	fun active_uniform_name(index: Int): String
	do
		var max_size = active_attribute_max_length
		return active_uniform_name_native(index, max_size).to_s
	end
	private fun active_uniform_name_native(index, max_size: Int): NativeString `{
		char *name = malloc(max_size);
		int size;
		GLenum type;
		glGetActiveUniform(recv, index, max_size, NULL, &size, &type, name);
		return name;
	`}

	# Size of the active uniform at `index`
	fun active_uniform_size(index: Int): Int `{
		int size;
		GLenum type;
		glGetActiveUniform(recv, index, 0, NULL, &size, &type, NULL);
		return size;
	`}

	# Type of the active uniform at `index`
	#
	# May be any data type supported by OpenGL ES 2.0 shaders.
	fun active_uniform_type(index: Int): GLDataType `{
		int size;
		GLenum type = 0;
		glGetActiveUniform(recv, index, 0, NULL, &size, &type, NULL);
		return type;
	`}
end

# Abstract OpenGL ES shader object, implemented by `GLFragmentShader` and `GLVertexShader`
extern class GLShader `{GLuint`}
	# Set the source of the shader
	fun source=(code: NativeString) `{
		glShaderSource(recv, 1, (GLchar const **)&code, NULL);
	`}

	# Source of the shader, if available
	#
	# Returns `null` if the source is not available, usually when the shader
	# was created from a binary file.
	fun source: nullable String
	do
		var size = query(0x8B88)
		if size == 0 then return null
		return source_native(size).to_s
	end

	private fun source_native(size: Int): NativeString `{
		GLchar *code = malloc(size);
		glGetShaderSource(recv, size, NULL, code);
		return code;
	`}

	# Query information on this shader
	protected fun query(pname: Int): Int `{
		int val;
		glGetShaderiv(recv, pname, &val);
		return val;
	`}

	# Try to compile `source` into a binary GPU program
	#
	# Check the result using `is_compiled` and `info_log`
	fun compile `{ glCompileShader(recv); `}

	# Has this shader been compiled?
	fun is_compiled: Bool do return query(0x8B81) != 0

	# Delete this shader
	fun delete `{ glDeleteShader(recv); `}

	# Has this shader been deleted?
	fun is_deleted: Bool do return query(0x8B80) != 0

	# Is this a valid shader?
	fun is_ok: Bool `{ return glIsShader(recv); `}

	# Retrieve the information log of this shader
	#
	# Useful with `link` and `validate`
	fun info_log: String import NativeString.to_s `{
		int size;
		glGetShaderiv(recv, GL_INFO_LOG_LENGTH, &size);
		GLchar *msg = malloc(size);
		glGetShaderInfoLog(recv, size, NULL, msg);
		return NativeString_to_s(msg);
	`}
end

# An OpenGL ES 2.0 fragment shader
extern class GLFragmentShader
	super GLShader

	# Create a new fragment shader
	#
	# The newly created instance should be checked using `is_ok`.
	new `{ return glCreateShader(GL_FRAGMENT_SHADER); `}
end

# An OpenGL ES 2.0 vertex shader
extern class GLVertexShader
	super GLShader

	# Create a new fragment shader
	#
	# The newly created instance should be checked using `is_ok`.
	new `{ return glCreateShader(GL_VERTEX_SHADER); `}
end

# An array of `Float` associated to a program variable
class VertexArray
	var index: Int

	# Number of data per vertex
	var count: Int

	protected var glfloat_array: NativeGLfloatArray

	init(index, count: Int, array: Array[Float])
	do
		self.index = index
		self.count = count
		self.glfloat_array = new NativeGLfloatArray(array.length)
		for k in [0..array.length[ do
			glfloat_array[k] = array[k]
		end
	end

	fun attrib_pointer do attrib_pointer_intern(index, count, glfloat_array)
	private fun attrib_pointer_intern(index, count: Int, array: NativeGLfloatArray) `{
		glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, 0, array);
	`}

	# Activate this ???
	fun enable do enable_native(index)
	private fun enable_native(index: Int) `{ glEnableVertexAttribArray(index); `}

	# Desactivate this ???
	fun disable do disable_native(index)
	private fun disable_native(index: Int) `{ glDisableVertexAttribArray(index); `}

	fun draw_arrays_triangles(from, count: Int) `{ glDrawArrays(GL_TRIANGLES, from, count); `}

	fun draw_arrays_triangle_strip(from, count: Int) `{ glDrawArrays(GL_TRIANGLE_STRIP, from, count); `}
end

redef universal Int
	fun vertex_attrib4f(x, y, z, w: Float) `{
		glVertexAttrib4f(recv, x, y, z, w);
	`}

	# `size` is components per vertex
	fun vertex_attrib_pointer(size: Int, array: NativeGLfloatArray) `{
		glVertexAttribPointer(recv, size, GL_FLOAT, GL_FALSE, 0, array);
	`}

	fun enable_vertex_attrib_array `{ glEnableVertexAttribArray(recv); `}

	fun disable_vertex_attrib_array `{ glDisableVertexAttribArray(recv); `}

	fun uniform_1i(index, x: Int) `{ glUniform1i(index, x); `}
end
#fun draw_arrays_triangles(from, count: Int) `{ glDrawArrays(GL_TRIANGLES, from, count); `}

#fun draw_arrays_triangle_strip(from, count: Int) `{ glDrawArrays(GL_TRIANGLE_STRIP, from, count); `}

# Low level array of `Float`
class GLfloatArray
	super CArray[Float]
	redef type NATIVE: NativeGLfloatArray

	#
	init(size: Int)
	is old_style_init do
		native_array = new NativeGLfloatArray(size)
		super size
	end

	#
	new from(array: Array[Float])
	do
		var arr = new GLfloatArray(array.length)
		arr.fill_from array
		return arr
	end

	#
	fun fill_from(array: Array[Float])
	do
		assert length >= array.length
		for k in [0..array.length[ do
			self[k] = array[k]
		end
	end
end

# An array of `int` in C (`int*`)
extern class NativeGLfloatArray `{ GLfloat* `}
	super NativeCArray
	redef type E: Float

	# Initialize a new NativeCIntArray of `size` elements.
	new(size: Int) `{ return calloc(size, sizeof(GLfloat)); `}

	redef fun [](index) `{ return recv[index]; `}
	redef fun []=(index, val) `{ recv[index] = val; `}

	redef fun +(offset) `{ return recv + offset; `}
end

# General type for OpenGL enumerations
extern class GLEnum `{ GLenum `}

	redef fun hash `{ return recv; `}

	redef fun ==(o) do return o != null and is_same_type(o) and o.hash == self.hash
end

extern class GLUint`{GLuint`}

	redef fun hash `{ return recv; `}

	redef fun ==(o) do return o != null and is_same_type(o) and o.hash == self.hash
end

# An OpenGL ES 2.0 error code
extern class GLError
	super GLEnum

	# Is there no error?
	fun is_ok: Bool do return is_no_error

	# Is this not an error?
	fun is_no_error: Bool `{ return recv == GL_NO_ERROR; `}

	fun is_invalid_enum: Bool `{ return recv == GL_INVALID_ENUM; `}
	fun is_invalid_value: Bool `{ return recv == GL_INVALID_VALUE; `}
	fun is_invalid_operation: Bool `{ return recv == GL_INVALID_OPERATION; `}
	fun is_invalid_framebuffer_operation: Bool `{ return recv == GL_INVALID_FRAMEBUFFER_OPERATION; `}
	fun is_out_of_memory: Bool `{ return recv == GL_OUT_OF_MEMORY; `}

	redef fun to_s
	do
		if is_no_error then return "No error"
		if is_invalid_enum then return "Invalid enum"
		if is_invalid_value then return "Invalid value"
		if is_invalid_operation then return "Invalid operation"
		if is_invalid_framebuffer_operation then return "invalid framebuffer operation"
		if is_out_of_memory then return "Out of memory"
		return "Truely unknown error"
	end
end

protected fun assert_no_gl_error
do
	var error = gl.error
	if not error.is_ok then
		print "GL error: {error}"
		abort
	end
end

# Min at 16 per specification.
fun max_vertex_attribs: Int do return gl.get_int(0x8864)

# An OpenGL ES 2.0 2D texture
class GLTexture
	var id: Int = gen is lazy

	fun gen: Int
	do
		var id = gen_native
		self.id = id
		return id
	end

	# Generate a single texture
	#
	# TODO optimize with a global texture pool
	private fun gen_native: Int `{
		int id;
		glGenTextures(1, &id);
		return id;
	`}

	fun bind do bind_native(id)
	private fun bind_native(id: Int) `{ glBindTexture(GL_TEXTURE_2D, id); `}

	fun active(offset: Int) `{ glActiveTexture(GL_TEXTURE0 + offset); `}

	new rgby_square
	do
		gl_pixel_store_pack_alignement 1 # 1 byte per color
		var tex = new GLTexture
		tex.gen
		tex.bind

		var pixels = [255, 0,   0,
		              0,   255, 0,
		              0,   0,   255,
		              255, 255, 0]
		var cpixels = new CByteArray.from(pixels)

		gl_tex_image2d(2, 2, cpixels.native_array, false)

		gl.tex_parameter_min_filter(gl_TEXTURE_2D, new GLTextureMinFilter.nearest)
		gl.tex_parameter_mag_filter(gl_TEXTURE_2D, new GLTextureMagFilter.linear)

		return tex
	end

	fun delete do delete_native(id)
	private fun delete_native(id: Int) `{ glDeleteTextures(1, (GLuint*)&id); `}
end

#
fun glBindTexture(target: GLTextureTarget, id: Int) `{ glBindTexture(target, id); `}

#
# Default is 4.
#
# Require: `[1, 2, 4, 8].has(val)`
fun gl_pixel_store_pack_alignement(val: Int) `{ glPixelStorei(GL_PACK_ALIGNMENT, val); `}

#
#
# Require: `[1, 2, 4, 8].has(val)`
fun gl_pixel_store_unpack_alignement(val: Int) `{ glPixelStorei(GL_UNPACK_ALIGNMENT, val); `}

fun gl_tex_image2d(width, height: Int, pixels: NativeCByteArray, has_alpha: Bool) `{
	int format = has_alpha? GL_RGBA: GL_RGB;
	glTexImage2D(GL_TEXTURE_2D, 0, format, width, height,
		0, format, GL_UNSIGNED_BYTE, pixels);
`}

# Texture minifying function
#
# Used by: `GLES::tex_parameter_min_filter`
extern class GLTextureMinFilter
	super GLEnum

	new nearest `{ return GL_NEAREST; `}
	new linear `{ return GL_LINEAR; `}
	new nearest_mipmap_nearest `{ return GL_NEAREST_MIPMAP_NEAREST; `}
	new linear_mipmap_nearest `{ return GL_LINEAR_MIPMAP_NEAREST; `}
	new nearest_mipmap_linear `{ return GL_NEAREST_MIPMAP_LINEAR; `}
	new linear_mipmap_linear `{ return GL_LINEAR_MIPMAP_LINEAR; `}
end

# Texture magnification function
#
# Used by: `GLES::tex_parameter_mag_filter`
extern class GLTextureMagFilter
	super GLEnum

	new nearest `{ return GL_NEAREST; `}
	new linear `{ return GL_LINEAR; `}
end

# Wrap parameter of a texture
#
# Used by: `tex_parameter_wrap_*`
extern class GLTextureWrap
	super GLEnum

	new clamp_to_edge `{ return GL_CLAMP_TO_EDGE; `}
	new mirrored_repeat `{ return GL_MIRRORED_REPEAT; `}
	new repeat `{ return GL_REPEAT; `}
end

# Target texture
#
# Used by: `tex_parameter_*`
extern class GLTextureTarget
	super GLEnum
end

#
fun gl_TEXTURE_2D: GLTextureTarget `{ return GL_TEXTURE_2D; `}

#
fun gl_TEXTURE_CUBE_MAP: GLTextureTarget `{ return GL_TEXTURE_CUBE_MAP; `}

# A server-side capability
class GLCap

	# TODO private init

	# Internal OpenGL integer for this capability
	private var val: Int

	# Enable this server-side capability
	fun enable do enable_native(val)
	private fun enable_native(cap: Int) `{ glEnable(cap); `}

	# Disable this server-side capability
	fun disable do disable_native(val)
	private fun disable_native(cap: Int) `{ glDisable(cap); `}

	redef fun hash do return val
	redef fun ==(o) do return o != null and is_same_type(o) and o.hash == self.hash
end

#
class GLRenderbuffer
	var id: Int = gen is lazy

	fun gen: Int
	do
		var id = gen_native
		self.id = id
		return id
	end

	# Generate a single renderbuffer
	#
	# TODO optimize with a global texture pool
	private fun gen_native: Int `{
		int id;
		glGenRenderbuffers(1, &id);
		return id;
	`}

	fun bind do bind_native(id)
	private fun bind_native(id: Int) `{ glBindRenderbuffer(GL_RENDERBUFFER, id); `}

	# TODO max samples GL_MAX_RENDERBUFFER_SIZE
	# TODO set id before, or keep independent
	fun storage(format: GLRenderbufferFormat, width, height: Int) `{
		glRenderbufferStorage(GL_RENDERBUFFER, format, width, height);
	`}

	# Must be `new GLFramebufferTarget`
	fun attach(target: GLFramebufferTarget, attachment: GLAttachment)
	do
		attach_native(target, attachment, id)
	end

	# TODO move to framebuffer?
	fun attach_native(target: GLFramebufferTarget, attachment: GLAttachment, id: Int) `{
		glFramebufferRenderbuffer(target, attachment, GL_RENDERBUFFER, id);
	`}
end

# Format for a renderbuffer
#
# Used by `GLRenderbuffer::storage`
extern class GLRenderbufferFormat
	super GLEnum
end

# 4 red, 4 green, 4 blue, 4 alpha bits
fun gl_RGBA4: GLRenderbufferFormat `{ return GL_RGBA4; `}

# 5 red, 6 green, 5 blue bits
fun gl_RGB565: GLRenderbufferFormat `{ return GL_RGB565; `}

# 5 red, 5 green, 5 blue, 1 alpha bits
fun gl_RGB_A1: GLRenderbufferFormat `{ return GL_RGB5_A1; `}

# 16 depth bits
fun gl_DEPTH_COMPNENT16: GLRenderbufferFormat `{ return GL_DEPTH_COMPONENT16; `}

# 8 stencil bits
fun gl_STENCIL_INDEX8: GLRenderbufferFormat `{ return GL_STENCIL_INDEX8; `}

# Renderbuffer attachment point to a framebuffer
#
# Used by `GLRenderbuffer::attach`
extern class GLAttachment
	super GLEnum
end

# First color attachment point
fun gl_COLOR_ATTACHMENT0: GLAttachment `{ return GL_COLOR_ATTACHMENT0; `}

# Depth attachment point
fun gl_DEPTH_ATTACHMENT: GLAttachment `{ return GL_DEPTH_ATTACHMENT; `}

# Stencil attachment
fun gl_STENCIL_ATTACHMENT: GLAttachment `{ return GL_STENCIL_ATTACHMENT; `}

redef class Sys
	private var gles = new GLES is lazy
end

# Entry points to OpenGL ES 2.0 services
fun gl: GLES do return sys.gles

# OpenGL ES 2.0 services
class GLES

	# Clear the color buffer to `red`, `green`, `blue` and `alpha`
	fun clear_color(red, green, blue, alpha: Float) `{
		glClearColor(red, green, blue, alpha);
	`}

	# Set the viewport
	fun viewport(x, y, width, height: Int) `{ glViewport(x, y, width, height); `}

	# Specify mapping of depth values from normalized device coordinates to window coordinates
	#
	# Default at `gl_depth_range(0.0, 1.0)`
	fun depth_range(near, far: Float) `{ glDepthRangef(near, far); `}

	# Define front- and back-facing polygons
	#
	# Front-facing polygons are clockwise if `value`, counter-clockwise otherwise.
	fun front_face=(value: Bool) `{ glFrontFace(value? GL_CW: GL_CCW); `}

	# Specify whether front- or back-facing polygons can be culled, default is `back` only
	#
	# One or both of `front` or `back` must be `true`. If you want to deactivate culling
	# use `(new GLCap.cull_face).disable`.
	#
	# Require: `front or back`
	fun cull_face(front, back: Bool)
	do
		assert not (front or back)
		cull_face_native(front, back)
	end

	private fun cull_face_native(front, back: Bool) `{
		glCullFace(front? back? GL_FRONT_AND_BACK: GL_BACK: GL_FRONT);
	`}

	# Clear the `buffer`
	fun clear(buffer: GLBuffer) `{ glClear(buffer); `}

	# Last error from OpenGL ES 2.0
	fun error: GLError `{ return glGetError(); `}

	# Query the boolean value at `key`
	private fun get_bool(key: Int): Bool `{
		GLboolean val;
		glGetBooleanv(key, &val);
		return val == GL_TRUE;
	`}

	# Query the floating point value at `key`
	private fun get_float(key: Int): Float `{
		GLfloat val;
		glGetFloatv(key, &val);
		return val;
	`}

	# Query the integer value at `key`
	private fun get_int(key: Int): Int `{
		GLint val;
		glGetIntegerv(key, &val);
		return val;
	`}

	# Does this driver support shader compilation?
	#
	# Should always return `true` in OpenGL ES 2.0 and 3.0.
	fun shader_compiler: Bool do return get_bool(0x8DFA)

	# Enable or disable writing into the depth buffer
	fun depth_mask(value: Bool) `{ glDepthMask(value); `}

	# Set the scale and units used to calculate depth values
	fun polygon_offset(factor, units: Float) `{ glPolygonOffset(factor, units); `}

	# Specify the width of rasterized lines
	fun line_width(width: Float) `{ glLineWidth(width); `}

	# Set the pixel arithmetic for the blending operations
	#
	# Defaultvalues before assignation:
	# * `src_factor`: `GLBlendFactor::one`
	# * `dst_factor`: `GLBlendFactor::zero`
	fun blend_func(src_factor, dst_factor: GLBlendFactor) `{
		glBlendFunc(src_factor, dst_factor);
	`}

	# Specify the value used for depth buffer comparisons
	#
	# Default value is `GLDepthFunc::less`
	#
	# Foreign: glDepthFunc
	fun depth_func(func: GLDepthFunc) `{ glDepthFunc(func); `}

	# Copy a block of pixels from the framebuffer of `fomat` and `typ` at `data`
	#
	# Foreign: glReadPixel
	fun read_pixels(x, y, width, height: Int, format: GLPixelFormat, typ: GLPixelType, data: Pointer) `{
		glReadPixels(x, y, width, height, format, typ, data);
	`}

	# Set the texture minifying function
	#
	# Foreign: glTexParameter with GL_TEXTURE_MIN_FILTER
	fun tex_parameter_min_filter(target: GLTextureTarget, value: GLTextureMinFilter) `{
		glTexParameteri(target, GL_TEXTURE_MIN_FILTER, value);
	`}

	# Set the texture magnification function
	#
	# Foreign: glTexParameter with GL_TEXTURE_MAG_FILTER
	fun tex_parameter_mag_filter(target: GLTextureTarget, value: GLTextureMagFilter) `{
		glTexParameteri(target, GL_TEXTURE_MAG_FILTER, value);
	`}

	# Set the texture wrap parameter for coordinates _s_
	#
	# Foreign: glTexParameter with GL_TEXTURE_WRAP_S
	fun tex_parameter_wrap_s(target: GLTextureTarget, value: GLTextureWrap) `{
		glTexParameteri(target, GL_TEXTURE_WRAP_S, value);
	`}

	# Set the texture wrap parameter for coordinates _t_
	#
	# Foreign: glTexParameter with GL_TEXTURE_WRAP_T
	fun tex_parameter_wrap_t(target: GLTextureTarget, value: GLTextureWrap) `{
		glTexParameteri(target, GL_TEXTURE_WRAP_T, value);
	`}

	# Render primitives from array data
	#
	# Foreign: glDrawArrays
	fun draw_arrays(mode: GLDrawMode, from, count: Int) `{ glDrawArrays(mode, from, count); `}

	# OpenGL server-side capabilities
	var capabilities = new GLCapabilities is lazy

	fun framebuffer_binding: Int `{
		int val;
		glGetIntegerv(GL_FRAMEBUFFER_BINDING, &val);
		return val;
	`}
end

# Bind `framebuffer` to a framebuffer target
#
# In OpenGL ES 2.0, `target` must be `gl_FRAMEBUFFER`.
fun glBindFramebuffer(target: GLFramebufferTarget, framebuffer: Int) `{
	glBindFramebuffer(target, framebuffer);
`}

# Target of `glBindFramebuffer`
extern class GLFramebufferTarget
	super GLEnum
end

# Target both reading and writing on the framebuffer with `glBindFramebuffer`
fun gl_FRAMEBUFFER: GLFramebufferTarget `{ return GL_FRAMEBUFFER; `}

# Bind `renderbuffer` to a renderbuffer target
#
# In OpenGL ES 2.0, `target` must be `gl_RENDERBUFFER`.
fun glBindRenderbuffer(target: GLRenderbufferTarget, renderbuffer: Int) `{
	glBindRenderbuffer(target, renderbuffer);
`}

# Target of `glBindRenderbuffer`
extern class GLRenderbufferTarget
	super GLEnum
end

# Target a renderbuffer with `glBindRenderbuffer`
fun gl_RENDERBUFFER: GLRenderbufferTarget `{ return GL_RENDERBUFFER; `}

# Specify implementation specific hints
fun glHint(target: GLHintTarget, mode: GLHintMode) `{
	glHint(target, mode);
`}

# Generate and fill set of mipmaps for a texture object
fun glGenerateMipmap(target: GLTextureTarget) `{ glGenerateMipmap(target); `}

# Bind a named buffer object
fun glBindBuffer(target: GLArrayBuffer, buffer: Int) `{
	glBindBuffer(target, buffer);
`}

# Completeness status of a framebuffer object
fun glCheckFramebufferStatus(target: GLFramebufferTarget): GLFramebufferStatus `{
	return glCheckFramebufferStatus(target);
`}

# Return value of `glCheckFramebufferStatus`
extern class GLFramebufferStatus
	super GLEnum

	redef fun to_s
	do
		if self == gl_FRAMEBUFFER_COMPLETE then return "complete"
		if self == gl_FRAMEBUFFER_INCOMPLETE_ATTACHMENT then return "incomplete attachment"
		if self == gl_FRAMEBUFFER_INCOMPLETE_DIMENSIONS then return "incomplete dimension"
		if self == gl_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT then return "incomplete missing attachment"
		if self == gl_FRAMEBUFFER_UNSUPPORTED then return "unsupported"
		return "unknown"
	end
end

# The framebuffer is complete
fun gl_FRAMEBUFFER_COMPLETE: GLFramebufferStatus `{
	return GL_FRAMEBUFFER_COMPLETE;
`}

# Not all framebuffer attachment points are framebuffer attachment complete
fun gl_FRAMEBUFFER_INCOMPLETE_ATTACHMENT: GLFramebufferStatus `{
	return GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
`}

# Not all attached images have the same width and height
fun gl_FRAMEBUFFER_INCOMPLETE_DIMENSIONS: GLFramebufferStatus `{
	return GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS;
`}

# No images are attached to the framebuffer
fun gl_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: GLFramebufferStatus `{
	return GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT;
`}

# The combination of internal formats of the attached images violates an implementation-dependent set of restrictions
fun gl_FRAMEBUFFER_UNSUPPORTED: GLFramebufferStatus `{
	return GL_FRAMEBUFFER_UNSUPPORTED;
`}

# Hint target for `glHint`
extern class GLHintTarget
	super GLEnum
end

# Indicates the quality of filtering when generating mipmap images
fun gl_GENERATE_MIPMAP_HINT: GLHintTarget `{ return GL_GENERATE_MIPMAP_HINT; `}

# Hint mode for `glHint`
extern class GLHintMode
	super GLEnum
end

# The most efficient option should be chosen
fun gl_FASTEST: GLHintMode `{ return GL_FASTEST; `}

# The most correct, or highest quality, option should be chosen
fun gl_NICEST: GLHintMode `{ return GL_NICEST; `}

# No preference
fun gl_DONT_CARE: GLHintMode `{ return GL_DONT_CARE; `}

# Target to which bind the buffer with `glBindBuffer`
extern class GLArrayBuffer
	super GLEnum
end

#
fun gl_ARRAY_BUFFER: GLArrayBuffer `{ return GL_ARRAY_BUFFER; `}

#
fun gl_ELEMENT_ARRAY_BUFFER: GLArrayBuffer `{ return GL_ELEMENT_ARRAY_BUFFER; `}

# Collection of textures or render targets
#
# One color, depth and stencil attachemns (total 3)
#
# * Singe-buffered
extern class GLFramebuffer
	super GLUint

	new `{
		GLuint ids;
		glGenFramebuffers(1, &ids);
		return ids;
	`}

	# Must be `new GLFramebufferTarget` in glesv2
	fun bind(target: GLFramebufferTarget) `{
		glBindFramebuffer(target, recv);
	`}

	fun attach_texture_2d(target: GLFramebufferTarget, attachment: GLAttachment,
		texture_target: GLTextureTarget,  texture: GLTexture, level: Int)
	do
		native_attach_texture_2d(target, attachment, texture_target, texture.id, level)
	end

	fun native_attach_texture_2d(target: GLFramebufferTarget, attachment: GLAttachment,
		texture_target: GLTextureTarget,  texture, level: Int) `{
		glFramebufferTexture2D(target, attachment, texture_target, texture, level);
	`}
end

# TODO render and framebuffer sets

# Entry point to OpenGL server-side capabilities
class GLCapabilities

	# GL capability: blend the computed fragment color values
	#
	# Foreign: GL_BLEND
	var blend: GLCap is lazy do return new GLCap(0x0BE2)

	# GL capability: cull polygons based of their winding in window coordinates
	#
	# Foreign: GL_CULL_FACE
	var cull_face: GLCap is lazy do return new GLCap(0x0B44)

	# GL capability: do depth comparisons and update the depth buffer
	#
	# Foreign: GL_DEPTH_TEST
	var depth_test: GLCap is lazy do return new GLCap(0x0B71)

	# GL capability: dither color components or indices before they are written to the color buffer
	#
	# Foreign: GL_DITHER
	var dither: GLCap is lazy do return new GLCap(0x0BE2)

	# GL capability: add an offset to depth values of a polygon fragment before depth test
	#
	# Foreign: GL_POLYGON_OFFSET_FILL
	var polygon_offset_fill: GLCap is lazy do return new GLCap(0x8037)

	# GL capability: compute a temporary coverage value where each bit is determined by the alpha value at the corresponding location
	#
	# Foreign: GL_SAMPLE_ALPHA_TO_COVERAGE
	var sample_alpha_to_coverage: GLCap is lazy do return new GLCap(0x809E)

	# GL capability: AND the fragment coverage with the temporary coverage value
	#
	# Foreign: GL_SAMPLE_COVERAGE
	var sample_coverage: GLCap is lazy do return new GLCap(0x80A0)

	# GL capability: discard fragments that are outside the scissor rectangle
	#
	# Foreign: GL_SCISSOR_TEST
	var scissor_test: GLCap is lazy do return new GLCap(0x0C11)

	# GL capability: do stencil testing and update the stencil buffer
	#
	# Foreign: GL_STENCIL_TEST
	var stencil_test: GLCap is lazy do return new GLCap(0x0B90)
end

# Float related data types of OpenGL ES 2.0 shaders
#
# Only data types supported by shader attributes, as seen with
# `GLProgram::active_attrib_type`.
extern class GLFloatDataType
	super GLEnum

	fun is_float: Bool `{ return recv == GL_FLOAT; `}
	fun is_float_vec2: Bool `{ return recv == GL_FLOAT_VEC2; `}
	fun is_float_vec3: Bool `{ return recv == GL_FLOAT_VEC3; `}
	fun is_float_vec4: Bool `{ return recv == GL_FLOAT_VEC4; `}
	fun is_float_mat2: Bool `{ return recv == GL_FLOAT_MAT2; `}
	fun is_float_mat3: Bool `{ return recv == GL_FLOAT_MAT3; `}
	fun is_float_mat4: Bool `{ return recv == GL_FLOAT_MAT4; `}

	# Instances of `GLFloatDataType` can be equal to instances of `GLDataType`
	redef fun ==(o)
	do
		return o != null and o isa GLFloatDataType and o.hash == self.hash
	end
end

# All data types of OpenGL ES 2.0 shaders
#
# These types can be used by shader uniforms, as seen with
# `GLProgram::active_uniform_type`.
extern class GLDataType
	super GLFloatDataType

	fun is_int: Bool `{ return recv == GL_INT; `}
	fun is_int_vec2: Bool `{ return recv == GL_INT_VEC2; `}
	fun is_int_vec3: Bool `{ return recv == GL_INT_VEC3; `}
	fun is_int_vec4: Bool `{ return recv == GL_INT_VEC4; `}
	fun is_bool: Bool `{ return recv == GL_BOOL; `}
	fun is_bool_vec2: Bool `{ return recv == GL_BOOL_VEC2; `}
	fun is_bool_vec3: Bool `{ return recv == GL_BOOL_VEC3; `}
	fun is_bool_vec4: Bool `{ return recv == GL_BOOL_VEC4; `}
	fun is_sampler_2d: Bool `{ return recv == GL_SAMPLER_2D; `}
	fun is_sampler_cube: Bool `{ return recv == GL_SAMPLER_CUBE; `}
end

# Kind of primitives to render with `GLES::draw_arrays`
extern class GLDrawMode
	super GLEnum

	new points `{ return GL_POINTS; `}
	new line_strip `{ return GL_LINE_STRIP; `}
	new line_loop `{ return GL_LINE_LOOP; `}
	new lines `{ return GL_LINES; `}
	new triangle_strip `{ return GL_TRIANGLE_STRIP; `}
	new triangle_fan `{ return GL_TRIANGLE_FAN; `}
	new triangles `{ return GL_TRIANGLES; `}
end

# Pixel arithmetic for blending operations
#
# Used by `GLES::blend_func`
extern class GLBlendFactor
	super GLEnum

	new zero `{ return GL_ZERO; `}
	new one `{ return GL_ONE; `}
	new src_color `{ return GL_SRC_COLOR; `}
	new one_minus_src_color `{ return GL_ONE_MINUS_SRC_COLOR; `}
	new dst_color `{ return GL_DST_COLOR; `}
	new one_minus_dst_color `{ return GL_ONE_MINUS_DST_COLOR; `}
	new src_alpha `{ return GL_SRC_ALPHA; `}
	new one_minus_src_alpha `{ return GL_ONE_MINUS_SRC_ALPHA; `}
	new dst_alpha `{ return GL_DST_ALPHA; `}
	new one_minus_dst_alpha `{ return GL_ONE_MINUS_DST_ALPHA; `}
	new constant_color `{ return GL_CONSTANT_COLOR; `}
	new one_minus_constant_color `{ return GL_ONE_MINUS_CONSTANT_COLOR; `}
	new constant_alpha `{ return GL_CONSTANT_ALPHA; `}
	new one_minus_constant_alpha `{ return GL_ONE_MINUS_CONSTANT_ALPHA; `}

	# Used for destination only
	new src_alpha_saturate `{ return GL_SRC_ALPHA_SATURATE; `}
end

# Condition under which a pixel will be drawn
#
# Used by `GLES::depth_func`
extern class GLDepthFunc
	super GLEnum

	 new never `{ return GL_NEVER; `}
	 new less `{ return GL_LESS; `}
	 new equal `{ return GL_EQUAL; `}
	 new lequal `{ return GL_LEQUAL; `}
	 new greater `{ return GL_GREATER; `}
	 new not_equal `{ return GL_NOTEQUAL; `}
	 new gequal `{ return GL_GEQUAL; `}
	 new always `{ return GL_ALWAYS; `}
end

# Format of pixel data
#
# Used by `GLES::read_pixels`
extern class GLPixelFormat
	super GLEnum

	new alpha `{ return GL_ALPHA; `}
	new rgb `{ return GL_RGB; `}
	new rgba `{ return GL_RGBA; `}
end

# Data type of pixel data
#
# Used by `GLES::read_pixels`
extern class GLPixelType
	super GLEnum

	new unsigned_byte `{ return GL_UNSIGNED_BYTE; `}
	new unsigned_short_5_6_5 `{ return GL_UNSIGNED_SHORT_5_6_5; `}
	new unsigned_short_4_4_4_4 `{ return GL_UNSIGNED_SHORT_4_4_4_4; `}
	new unsigned_short_5_5_5_1 `{ return GL_UNSIGNED_SHORT_5_5_5_1; `}
end

# Set of buffers as a bitwise OR mask, used by `GLES::clear`
#
# ~~~
# var buffers = (new GLBuffer).color.depth
# gl.clear buffers
# ~~~
extern class GLBuffer `{ GLbitfield `}
	# Get an empty set of buffers
	new `{ return 0; `}

	# Add the color buffer to the returned buffer set
	fun color: GLBuffer `{ return recv | GL_COLOR_BUFFER_BIT; `}

	# Add the depth buffer to the returned buffer set
	fun depth: GLBuffer `{ return recv | GL_DEPTH_BUFFER_BIT; `}

	# Add the stencil buffer to the returned buffer set
	fun stencil: GLBuffer `{ return recv | GL_STENCIL_BUFFER_BIT; `}
end

extern class NativeGLfloatMatrix `{ GLfloat* `}

	new alloc `{ return malloc(4*4*sizeof(GLfloat)); `}

	fun set_identity
	do
		for i in 4.times do
			for j in 4.times do
				self[i, j] = if i == j then 1.0 else 0.0
			end
		end
	end

	fun [](x, y: Int): Float `{ return recv[y*4+x]; `}
	fun []=(x, y: Int, val: Float) `{ recv[y*4+x] = val; `}
end

redef class Matrix[N]
	# Copy content of this matrix to a `NativeGLfloatMatrix`
	fun fill_native(native: NativeGLfloatMatrix)
	do
		for i in width.times do
			for j in height.times do
				native[i, j] = self[i, j].to_f
			end
		end
	end
end
