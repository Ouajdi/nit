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

# Gammit implementation for GNU/Linux using `egl` and locally SDL & X11
module linux

import x11
import sdl
import gammit::egl

intrude import glesv2_display
import gammit::standalone

redef class GammitDisplay

	# Setup SDL, X11, EGL and GLES in order
	redef fun setup(window_width, window_height)
	do
		self.sdl_display = setup_sdl(window_width, window_height)
		var x11_display = setup_x11
		var window_handle = window_handle
		setup_egl_display x11_display
		select_egl_config(8, 8, 8, 8, 8, 0, 0)
		setup_egl_context window_handle
		setup_gles
	end

	# Close GLES, EGL and SDL in reverse order of `setup` (nothing to do for X11)
	redef fun close
	do
		close_gles
		close_egl
		close_sdl
	end

	#
	## SDL
	#

	# The SDL display managing the winodw and events
	var sdl_display: SDLDisplay

	# Setup the SDL display and lib
	fun setup_sdl(window_width, window_height: Int): SDLDisplay
	do
		var sdl_display = new SDLDisplay(window_width, window_height)
		return sdl_display
	end

	# Close the SDL display
	fun close_sdl do sdl_display.destroy

	# Get a native handle to the current SDL window
	fun window_handle: Pointer
	do
		var sdl_wm_info = new SDLSystemWindowManagerInfo
		return sdl_wm_info.x11_window_handle
	end

	# Implement texture loading with SDL
	redef fun load_texture_from_assets(path)
	do
		var sdl_image = new SDLImage.from_file("assets"/path)
		return load_texture_from_pixels(sdl_image.pixels,
			sdl_image.width0, sdl_image.height0, true) #sdl_image.amask)
	end

	redef fun check_lock_cursor
	do
		if lock_cursor and sdl_display.has_input_focus then
			sdl_display.ignore_mouse_motion_events = true
			sdl_display.warp_mouse(width/2, height/2)
			sdl_display.ignore_mouse_motion_events = false
		end
	end

	redef fun show_cursor: Bool do return sdl_display.show_cursor

	redef fun show_cursor=(val: Bool) do sdl_display.show_cursor = val

	#
	## X11
	#

	# Get a native handle to the current X11 display
	fun setup_x11: Pointer
	do
		var x11_display = x_open_default_display
		assert not x11_display.address_is_null else print "x11 fail"
		return x11_display
	end
end

redef class GammitApp
	redef fun generate_events
	do
		var display = self.display
		if display != null then
			var events = display.sdl_display.events
			display.check_lock_cursor # HACK
			for event in events do
				accept_event(event)
			end
		end
	end
end
