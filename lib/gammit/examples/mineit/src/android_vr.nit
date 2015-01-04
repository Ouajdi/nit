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

# Mineit on Android in virtual reality with Google Cardboard
module android_vr is
	app_version(0, 5, git_revision)
	app_name "Mineit VR"
	java_package "net.xymus.mineit_vr"
	android_manifest_activity """
		android:theme="@android:style/Theme.NoTitleBar.Fullscreen"
		android:screenOrientation="landscape""""
	min_api_version 19
end

import gammit::android
import ::android::cardboard
import ::android::gamepad

import vr
import optimized

redef class MineitWorld

	# Tweak the world size, make it deep
	redef var ground_cover = [-8 .. 8]
	redef var ground_depth = 20

	# Slow down our player so it's easier to navigate
	redef var speed = 0.05
end

redef class SimpleCamera
	# Do not use `yaw` and `pitch`, the value will instead originate from the Cardboard API
	redef var rotation_matrix = new Matrix[Float].identity(4)

	# Get the angle value from the `rotation_matrix`
	redef fun pitch
	do
		var a = rotation_matrix[0, 1]
		var b = rotation_matrix[1, 1]
		return -atan2(a, b)
	end

	# Get the angle value from the `rotation_matrix`
	redef fun yaw
	do
		var a = rotation_matrix[2, 0]
		var b = rotation_matrix[2, 2]
		return -atan2(a, b)
	end
end

redef class GammitApp
	# Use Cardboard's head tacking features
	var head_tracker: nullable NativeHeadTracker = null

	redef fun setup
	do
		super

		# Initialize the Cardboard head orientation tracker service
		head_tracker = new NativeHeadTracker(app.native_activity)
		head_tracker.neck_model_enabled = true
		head_tracker.start_tracking

		# Set a wide field of view
		camera.field_of_view_y = 1.0
	end

	# Do not show any UI
	redef fun setup_ui do end

	# We reuse this array to get the rotation matrix from the Java library
	private var java_rotation_matrix = new JavaFloatArray(16) is lazy

	redef fun frame_logic
	do
		# Extract rotation matrix from Cardboard
		head_tracker.last_head_view(java_rotation_matrix, 0)

		# Copy values from the Java array to our matrix
		for y in [0..4[ do
			for x in [0..4[ do
				camera.rotation_matrix[y, x] = java_rotation_matrix[y*4+x]
			end
		end

		super
	end

	redef fun accept_event(event)
	do
		### Gamepad support


		### Mouse support (probably over bluetooth) for people without a compatible gamepad
		if event isa AndroidPointerEvent then
			if event.pressed then # TODO use just_went_down
				# Move forward
				#display.keys.downs.add "w"
			else # event.depressed
				#if display.keys.downs.has("w") then display.keys.downs.remove "w"
			end
			return true
		else if event isa AndroidKeyEvent then
			print event.key_code
			if event.is_back_key or event.is_a then
				# mine
				if event.is_down then act(display.width/2, display.height/2, true)
				return true
			else if event.key_code == 125 or event.is_b then
				# place
				if event.is_down then act(display.width/2, display.height/2, false)
				return true
			else if event.is_dpad then
				var letter = null
				if event.is_dpad_up then letter = "w"
				if event.is_dpad_down then letter = "s"
				if event.is_dpad_left then letter = "a"
				if event.is_dpad_right then letter = "d"
				assert letter != null

				if event.is_down then
					display.keys.downs.add letter
				else
					display.keys.downs.remove letter
					#if display.keys.downs.has("w") then display.keys.downs.remove "w"
				end
			end
		else if event isa AndroidKeyEvent and event.is_back_key then
			# Catch all back keys so it doesn't leave our app
			return true
		end

		return super
	end
end

redef class App
	redef fun pause
	do
		var tracker = gammit.head_tracker
		if tracker != null then
			tracker.stop_tracking
		end
	end

	redef fun resume
	do
		var tracker = gammit.head_tracker
		if tracker != null then
			tracker.start_tracking
		end
	end
end
