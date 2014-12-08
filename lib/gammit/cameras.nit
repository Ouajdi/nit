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

# Camera implementations for Gammit
module cameras

import glesv2_display

# A camera giving a point of view in the world
abstract class Camera
	# The associated `GammitDisplay`
	var display: GammitDisplay

	# Position of this camera in world space
	var position = new Point3d[Float](0.0, 0.0, 0.0) is writable

	# The Model-View-Projection matrix created by this camera
	#
	# This method should only be called by the display at the moment
	# of drawing to the screen.
	fun mvp_matrix: Matrix[Float] is abstract
end

# Simple camera for an FPS game, and for an RPG or RTS if looking downwards
class SimpleCamera
	super Camera

	# Rotation around the X axis (looking down or up)
	var down_up = 0.0 is writable

	# Rotation around Y the axis (looking left or right)
	var left_right = 0.0 is writable

	# Look around sensitivity, used by `turn`
	var sensitivity = 0.005 is writable

	# Field of view in radians on the vertical axis of the screen
	#
	# Default at `0.8`
	var field_of_view_y = 0.8 is writable

	# Clipping wall near the camera, in world dimensions
	#
	# Default at `0.01`.
	var near = 0.01 is writable

	# Clipping wall the farthest of the camera, in world dimensions
	#
	# Default at `100.0` but this one should be adapted to each context.
	var far = 100.0 is writable

	# Apply a mouse movement (or similar) to the camera
	#
	# `dx` and `dy` are relative mouse movements in pixels.
	fun turn(dx, dy: Float)
	do
		# Moving on x, turn around the y axis
		left_right -= dx*sensitivity
		down_up -= dy*sensitivity

		# Protect rotation around then x axis for not falling on your back
		down_up = down_up.min(pi/2.0)
		down_up = down_up.max(-pi/2.0)
	end

	# Move the camera considering the current orientation
	fun move(dx, dy, dz: Float)
	do
		# +dz move forward
		position.x -= left_right.sin*dz
		position.z -= left_right.cos*dz

		# +dx strafe to the right
		position.x += left_right.cos*dx
		position.z -= left_right.sin*dx

		# +dz move towards the sky
		position.y += dy
	end

	#
	fun rotation_matrix: Matrix[Float]
	do
		var view = new Matrix[Float].identity(4)

		# Rotate the camera, first by looking left or right, then up or down
		view.rotate(left_right, 0.0, 1.0, 0.0)
		view.rotate(down_up, 1.0, 0.0, 0.0)

		return view
	end

	redef fun mvp_matrix
	do
		var view = new Matrix[Float].identity(4)

		# Translate the world away from the camera
		view.translate(-position.x/2.0, -position.y/2.0, -position.z/2.0)

		# Rotate the camera, first by looking left or right, then up or down
		view = view * rotation_matrix

		# Use a projection matrix with a depth 
		var projection = new Matrix[Float].perspective(pi*field_of_view_y/2.0,
			display.aspect_ratio, near, far)

		return view * projection
	end
end

class TopDownCamera
	#var projection = new Matrix[Float].orthogonal(-0.5*display.aspect_ratio, 0.5*display.aspect_ratio, 0.5, -0.5, 0.0, 1.0)
end
