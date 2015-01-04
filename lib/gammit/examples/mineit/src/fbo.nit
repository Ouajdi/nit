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

# ...
#
module fbo

import mineit
import linux

class SimpleFBO
	var width = 640
	var height = 640

	var fbo: GLFramebuffer is noinit

	init
	do
		var color = new GLRenderbuffer

		var error = gl.error
		assert error.is_ok else print "OpenGL error: {error}"
		color.storage(new GLRenderbufferFormat.rgb565, width, height)

		error = gl.error
		assert error.is_ok else print "OpenGL error: {error}"

		var depth = new GLRenderbuffer
		depth.storage(new GLRenderbufferFormat.depth_component_16, width, height)

		error = gl.error
		assert error.is_ok else print "OpenGL error: {error}"

		fbo = new GLFramebuffer
		fbo.bind(new GLFramebufferTarget)
		depth.attach(new GLFramebufferTarget, new GLAttachment.depth)
		depth.attach(new GLFramebufferTarget, new GLAttachment.color0)

		error = gl.error
		assert error.is_ok else print "OpenGL error: {error}"
	end
end

redef class GammitDisplay

	# The aspect ration (in each eye) is half of the screen
	#redef fun aspect_ratio do return super / 2.0

	#
	var fbo = new SimpleFBO is lazy

	redef fun draw_all_the_things
	do
		# update camera
		fbo.fbo.bind(new GLFramebufferTarget)
		var error = gl.error
		assert error.is_ok else print "OpenGL error: {error}"

		#super
		error = gl.error
		assert error.is_ok else print "OpenGL error: {error}"

		#gl.bind_buffer(new GLArrayBuffer, 0)
		error = gl.error
		assert error.is_ok else print "OpenGL error: {error}"

		super
		error = gl.error
		assert error.is_ok else print "OpenGL error: {error}"
	end
end
