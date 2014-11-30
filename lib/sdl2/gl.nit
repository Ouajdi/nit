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

#
module gl is pkgconfig "sdl2"

import sdl2_base

in "C Header" `{
	#include <SDL2/SDL_opengl.h>
`}

redef class SDL
	#
	fun gl_attribute(attr: SDLGLAttr): Int `{
		int val;
		SDL_GL_GetAttribute(attr, &val);
		return val;
	`}

	#
	fun gl_attribute=(attr: SDLGLAttr, val: Int) `{
		SDL_GL_SetAttribute(attr, val);
	`}

	#
	var gl_context_profile = new SDLGLContextProfile is lazy
end

#
class GL
end

#
redef class SDLWindow
	#
	fun gl_swap `{ SDL_GL_SwapWindow(recv); `}

	#
	fun current_context=(context: SDLGLContext) `{
		SDL_GL_MakeCurrent(recv, context);
	`}
end

#
extern class SDLGLContext `{ SDL_GLContext `}
	#
	new (window: SDLWindow): SDLGLContext `{ return SDL_GL_CreateContext(window); `}

	#
	fun delete `{ SDL_GL_DeleteContext(recv); `}
end

extern class SDLGLAttr `{ int `}
	new red_size `{ return SDL_GL_RED_SIZE; `}
	new green_size `{ return SDL_GL_GREEN_SIZE; `}
	new blue_size `{ return SDL_GL_BLUE_SIZE; `}
	new alpha_size `{ return SDL_GL_ALPHA_SIZE; `}
	new buffer_size `{ return SDL_GL_BUFFER_SIZE; `}
	new doublebuffer `{ return SDL_GL_DOUBLEBUFFER; `}
	new depth_size `{ return SDL_GL_DEPTH_SIZE; `}
	new stencil_size `{ return SDL_GL_STENCIL_SIZE; `}
	new context_major_version `{ return SDL_GL_CONTEXT_MAJOR_VERSION; `}
	new context_minor_version `{ return SDL_GL_CONTEXT_MINOR_VERSION; `}
	new context_profile_mask `{ return SDL_GL_CONTEXT_PROFILE_MASK; `}
	new share_with_current_context `{ return SDL_GL_SHARE_WITH_CURRENT_CONTEXT; `}

	# TODO
	#
	# SDL_GL_ACCUM_RED_SIZE
	# SDL_GL_ACCUM_GREEN_SIZE
	# SDL_GL_ACCUM_BLUE_SIZE
	# SDL_GL_ACCUM_ALPHA_SIZE
	# SDL_GL_STEREO
	# SDL_GL_MULTISAMPLEBUFFERS
	# SDL_GL_MULTISAMPLESAMPLES
	# SDL_GL_ACCELERATED_VISUAL
	# SDL_GL_RETAINED_BACKING
	# SDL_GL_CONTEXT_FLAGS
	# SDL_GL_FRAMEBUFFER_SRGB_CAPABLE
end

class SDLGLContextProfile
	fun core: Int `{ return SDL_GL_CONTEXT_PROFILE_CORE; `}
	fun compatibility: Int `{ return SDL_GL_CONTEXT_PROFILE_COMPATIBILITY; `}
	fun es: Int `{ return SDL_GL_CONTEXT_PROFILE_ES; `}
end
