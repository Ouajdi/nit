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

# Defines abstract display classes
# Game And MultiMedia in nIT
module abstract_display

import geometry
import colors
import c

import glesv2

# Any class with a size
interface Sized
	fun width: Int is abstract
	fun height: Int is abstract
end

class VisibleArray
	super HashSet[Visible]
end

interface Drawable
end

# General class for everything drawable to
# Is used by drawable images and display
abstract class Canvas
	var entries = new VisibleArray

	# Set viewport for drawing
	fun set_viewport(sized: Sized) is abstract

	# If different than null, `draw_all_the_things` will clear the window with the given color
	var background_color: nullable Color = new Color.black is writable
end

# General display class, is sized and drawable
abstract class Display
	super Sized
	super Canvas

	type T: Texture

	fun close do end

	fun draw_all_the_things is abstract

	fun add(e: Visible)
	do
		entries.add e
	end

	fun load_texture_from_assets(path: String): T is abstract

	fun load_texture_from_pixels(pixels: NativeCByteArray, width, height: Int, has_alpha: Bool): T is abstract
end

class BaseVisible
	super IPoint[Numeric]
end

class Visible
	super BaseVisible
	super IPoint3d[Numeric]

	#
	var color = new Color.white is writable

	#
	var scale = 1.0 is writable

	fun vertices: Array[Float] is abstract

	var texture: nullable Texture = null is writable

	fun draw_mode: GLDrawMode do return new GLDrawMode.triangles

	var program: nullable GammitProgram = null is writable
end

class VisibleSquare
	super Visible

	redef var vertices = [-0.5, -0.5, 0.0,
						  -0.5,  0.5, 0.0,
						   0.5,  0.5, 0.0,
						  -0.5, -0.5, 0.0,
						   0.5,  0.5, 0.0,
						   0.5, -0.5, 0.0]
end

class VisibleCube
	super Visible

	redef var vertices is lazy do
		var a = [-0.5, -0.5, -0.5]
		var b = [ 0.5, -0.5, -0.5]
		var c = [-0.5,  0.5, -0.5]
		var d = [ 0.5,  0.5, -0.5]

		var e = [-0.5, -0.5,  0.5]
		var f = [ 0.5, -0.5,  0.5]
		var g = [-0.5,  0.5,  0.5]
		var h = [ 0.5,  0.5,  0.5]

		var vertices = new Array[Float]
		for v in [a, c, d, a, d, b, # front
		          f, h, g, f, g, e, # back
		          b, d, h, b, h, f, # right
		          e, g, c, e, c, a, # left
		          e, a, b, e, b, f, # bottom
		          c, g, h, c, h, d  # top
				  ] do vertices.add_all v
		return vertices
	end
end

#class VisibleLine

class VisibleLines
	super Visible

	# Need at least 2
	redef var vertices

	redef fun draw_mode do return new GLDrawMode.lines
end

#class VisiblePolygon

class VisiblePoint
	super Visible

	redef fun draw_mode do return new GLDrawMode.points
end

# A Gammit texture
class Texture
	# Get a reference to a subportion of this texture
	fun subtexture(left, top, width, height: Int): Texture is abstract
end

abstract class GammitProgram
end

abstract class Selectable
	super Visible
end
