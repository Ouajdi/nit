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

# Mineit on Android with simple overlay UI and touch controls
module android is
	app_version(0, 5, git_revision)
	app_name "Mineit"
	java_package "net.xymus.mineit"
	android_manifest_activity """android:screenOrientation="landscape""""
end

import gammit::android
import ::android::debug
import ::android::gamepad

import mineit
import optimized

redef class GammitApp

	redef fun setup_ui
	do
		super

		# Add overlay controls
		var texture = new GammitGLTexture("android_controls.png")
		var ts = texture.width/2
		var look = texture.subtexture(0, 0, ts, ts)
		var move = texture.subtexture(ts, 0, ts, ts)
		var mine = texture.subtexture(0, ts, ts, ts)
		var place = texture.subtexture(ts, ts, ts, ts)

		# Look around
		var icon = new UIElement(-1.8, 0.0, 0.0)
		icon.texture = look
		icon.program = display.ui_program
		display.add icon

		# Move
		icon = new UIElement(1.8, -1.0, 0.0)
		icon.texture = move
		icon.program = display.ui_program
		display.add icon

		# Mine
		icon = new UIElement(1.2, 1.0, 0.0)
		icon.texture = mine
		icon.program = display.ui_program
		display.add icon

		# Place blocks
		icon = new UIElement(2.4, 1.0, 0.0)
		icon.texture = place
		icon.program = display.ui_program
		display.add icon
	end

	redef fun accept_event(event)
	do
		#      |
		#      |   forward
		# look +------+------
		#      | mine | place
		#      |      | block

		if event isa AndroidPointerEvent then
			var x = event.x.to_i
			var y = event.y.to_i

			if x < display.width/2 then
				# look
				var rel_x = x - display.width/4
				var rel_y = y - display.height/2

				if event.pressed then
					camera.turn(rel_x.to_f/10.0, rel_y.to_f/50.0)
				end
			else
				if y < display.height/2 then
					# move
					if event.pressed then
						display.keys.downs.add "w"
					else # event.depressed
						if display.keys.downs.has("w") then display.keys.downs.remove "w"
					end
				else if event.depressed then
					var mine = x < display.width*3/4
					act(display.width/2, display.height/2, mine)
				end
			end

			return true
		end

		if event isa AndroidKeyEvent and event.is_back_key then
			print sys.time_stats
			return false
		end

		return super
	end

	private var tick = 1

	redef fun frame_logic
	do
		if not app.paused then super

		# Show the perf stats once in a while
		tick += 1
		if tick % 1000 == 0 then print sys.time_stats
	end
end
