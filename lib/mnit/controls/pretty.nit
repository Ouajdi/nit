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

# Improves controls and smart_display to show controls with background
module pretty

import mnit
import controls

# Image set used for borders
class BorderImageSet
	# corners
	var tl: Image
	var tr: Image
	var bl: Image
	var br: Image

	# flat borders
	var t: Image
	var b: Image
	var l: Image
	var r: Image

	# center
	var c: Image

	init default do from_image("controls/default.png", 8)

	init(path: String)
	do
		tl = app.load_image("{path}/tl.png")
		tr = app.load_image("{path}/tr.png")
		bl = app.load_image("{path}/bl.png")
		br = app.load_image("{path}/br.png")
		t = app.load_image("{path}/t.png")
		b = app.load_image("{path}/b.png")
		l = app.load_image("{path}/l.png")
		r = app.load_image("{path}/r.png")
		c = app.load_image("{path}/c.png")
	end

	init from_image(path: String, tile_size: Int)
	do
		var ts = tile_size
		var img = app.load_image(path)

		assert img.width >= 3*ts and img.height >= 3*ts

		tl = img.subimage(0, 0, ts, ts)
		tr = img.subimage(2*ts, 0, ts, ts)
		bl = img.subimage(0, 2*ts, ts, ts)
		br = img.subimage(2*ts, 2*ts, ts, ts)
		t = img.subimage(ts, 0, ts, ts)
		b = img.subimage(ts, 2*ts, ts, ts)
		l = img.subimage(0, ts, ts, ts)
		r = img.subimage(2*ts, ts, ts, ts)
		c = img.subimage(ts, ts, ts, ts)
	end
end

redef class RectangleControl

	# border images specific to this control
	var border_images: nullable BorderImageSet = app.border_images is lazy, writable

	# a better draw back implementation using border images when possible
	redef fun draw_back(display)
	do
		var bi = border_images
		if bi == null then bi = app.border_images

		if bi != null then
			var s = bi.tl.width # TODO do better
			var r = right - s # inside border positions
			var l = left + s
			var t = top + s
			var b = bottom - s

			# corners
			display.blit_scaled(bi.tl, left, top, s, s)
			display.blit_scaled(bi.tr, r, top, s, s)
			display.blit_scaled(bi.bl, left, b, s, s)
			display.blit_scaled(bi.br, r, b, s, s)

			# sides
			display.blit_stretched(bi.t, r.to_f, top.to_f, r.to_f, t.to_f, l.to_f, t.to_f, l.to_f, top.to_f)
			display.blit_stretched(bi.b, r.to_f, b.to_f, r.to_f,  bottom.to_f, l.to_f, bottom.to_f, l.to_f, b.to_f)
			display.blit_stretched(bi.r, l.to_f, t.to_f, l.to_f, b.to_f, left.to_f, b.to_f, left.to_f, t.to_f)
			display.blit_stretched(bi.l, right.to_f, t.to_f, right.to_f, b.to_f, r.to_f, b.to_f, r.to_f, t.to_f)
			# TODO check images l vs r

			# center
			display.blit_stretched(bi.c, l.to_f, t.to_f, r.to_f, t.to_f, r.to_f, b.to_f, l.to_f, b.to_f)
		end

		super
	end
end

redef class App
	fun load_images_for_controls
	do
		border_images = new BorderImageSet.default
	end

	# the default border images
	var border_images: nullable BorderImageSet = null
end
