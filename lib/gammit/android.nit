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

# Gammit implementation for Android
module android is android_manifest """
<uses-feature android:glEsVersion="0x00020000"/>"""

import ::android
intrude import ::android::input_events
import ::android::png
import gammit::egl

intrude import glesv2_display
import gammit

in "C" `{
	#include <android_native_app_glue.h>
`}

private fun egl_default_display: Pointer `{ return EGL_DEFAULT_DISPLAY; `}

redef class GammitDisplay

	# Setup EGL and GLES
	redef fun setup(window_width, window_height)
	do
		var native_display = egl_default_display
		var native_window = app.native_app_glue.window

		setup_egl_display native_display
		#select_egl_config(5, 6, 5, 0, 8, 0, 0)
		select_egl_config(4, 4, 4, 0, 8, 0, 0)

		# Android only
		var format = egl_config.attribs(egl_display).native_visual_id
		native_window.set_buffer_geometry format

		setup_egl_context native_window
		setup_gles
	end

	# Close GLES and EGL in reverse order of `setup`
	redef fun close
	do
		close_gles
		close_egl
	end

	redef fun load_texture_from_assets(path)
	do
		var asset = app.native_app_glue.ndk_native_activity.load_asset_from_apk(path.to_cstring)
		assert asset != null else print "asset not found at: {path}"

		var png_texture = asset.to_png_texture
		assert png_texture != null
		
		return load_texture_from_pixels(png_texture.pixels,
			png_texture.width, png_texture.height, png_texture.has_alpha) #sdl_image.amask)
	end
end

redef class GammitApp
	redef fun generate_events do app.poll_looper 0
end

redef class App
	redef fun native_input_key(event)
	do
		var gammit = gammit
		if gammit != null then
			return gammit.accept_event(event)
		end

		return false
	end

	redef fun native_input_motion(event)
	do
		var gammit = gammit
		if gammit != null then
			var ie = new AndroidMotionEvent(event)
			var handled = gammit.accept_event(ie)

			if not handled then
				for pe in ie.pointers do
					handled = gammit.accept_event(pe) or handled
				end
			end
		end

		return false
	end

	redef fun loop_body
	do
		super

		app.poll_looper 0
	end

	redef fun window_resized
	do
		super

		gammit.display.update_size
	end
end

redef extern class ANativeWindow
	#
	fun set_buffer_geometry(format: Int): Bool `{
		return ANativeWindow_setBuffersGeometry(recv, 0, 0, (EGLint)format);
	`}
end
