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

# Core Gamnit features
#
# Use `gammit` for portability.
module standalone

import mnit_input

import glesv2_display
import keys
import cameras

#
class GammitApp
	#
	var display: nullable GammitDisplay = null is writable

	#
	#
	# * Create the display and assign it to `self.display`
	# * Setup the world, main menu or loading screen
	fun setup
	do
		var display = new GammitDisplay(1920, 1200)
		self.display = display

		show_splash_screen

		load_textures
	end

	# Load the main textures
	fun load_textures do end

	# May load textyres
	fun show_splash_screen do end

	#
	fun frame_logic do end

	#
	fun generate_events do end

	#
	fun run
	do
		loop
			frame_logic
			display.draw_all_the_things
			generate_events
		end
	end

	#
	fun accept_event(event: InputEvent): Bool do return false
end

var gammit_app = new GammitApp
gammit_app.setup
gammit_app.run
