# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
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

# EGL usage to implement Gammit on GNU/Linux and Android
module egl

import ::egl

intrude import glesv2_display
import gammit::standalone

redef class GammitDisplay

	# The EGL display
	var egl_display: EGLDisplay

	# The EGL context
	var egl_context: EGLContext

	# The EGL surface for the window
	var window_surface: EGLSurface

	# The selected EGL configuration
	var egl_config: EGLConfig

	# Setup the EGL display for the given `x11_display`
	fun setup_egl_display(x11_display: Pointer)
	do
		var egl_display = new EGLDisplay(x11_display)
		assert egl_display.is_valid else print "EGL display is not valid"
		egl_display.initialize
		assert egl_display.is_valid else print egl_display.error

		self.egl_display = egl_display
	end

	# Select an EGL config
	fun select_egl_config(blue, green, red, alpha, depth, stencil, sample: Int)
	do
		var config_chooser = new EGLConfigChooser
		config_chooser.renderable_type_egl
		config_chooser.surface_type_egl
		config_chooser.blue_size = blue
		config_chooser.green_size = green
		config_chooser.red_size = red
		if alpha > 0 then config_chooser.alpha_size = alpha
		if depth > 0 then config_chooser.depth_size = depth
		if stencil > 0 then config_chooser.stencil_size = stencil
		if sample > 0 then config_chooser.sample_buffers = sample
		config_chooser.close

		var configs = config_chooser.choose(egl_display)
		assert configs != null else print "choosing config failed: {egl_display.error}"
		assert not configs.is_empty else print "no EGL config"

		# TODO keep?
		for config in configs do
			var attribs = config.attribs(egl_display)
			print "* Conformant to: {attribs.conformant}"
			print "  Caveats: {attribs.caveat}"
			print "  Size of RGBA: {attribs.red_size} {attribs.green_size} {attribs.blue_size} {attribs.alpha_size}"
			print "  Buffer, depth, stencil: {attribs.buffer_size} {attribs.depth_size} {attribs.stencil_size}"
		end

		self.egl_config = configs.first
	end

	# Setup the EGL context for the given `window_handle`
	fun setup_egl_context(window_handle: Pointer)
	do
		window_surface = egl_display.create_window_surface(egl_config, window_handle, [0])
		assert window_surface.is_ok else print egl_display.error

		egl_context = egl_display.create_context(egl_config)
		assert egl_context.is_ok else print egl_display.error

		var make_current_res = egl_display.make_current(window_surface, window_surface, egl_context)
		assert make_current_res

		width = window_surface.attribs(egl_display).width
		height = window_surface.attribs(egl_display).height

		assert egl_bind_opengl_es_api else print "eglBingAPI failed: {egl_display.error}"
	end

	# Close the EGL context cleanly
	fun close_egl
	do
		egl_display.make_current(new EGLSurface.none, new EGLSurface.none, new EGLContext.none)
		egl_display.destroy_context(egl_context)
		egl_display.destroy_surface(window_surface)
	end

	# Flip the screen after drawing
	redef fun draw_all_the_things
	do
		# TODO keep?
		egl_display.make_current(window_surface, window_surface, egl_context)

		super
		egl_display.swap_buffers(window_surface)
	end
end
