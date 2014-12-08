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
	android_manifest_activity """
		android:theme="@android:style/Theme.NoTitleBar.Fullscreen"
		android:screenOrientation="landscape""""
	min_api_version 19
end

import gammit::android
import ::android::cardboard

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
	# Do not use `roll` and `pitch`, the value will instead come from the Cardboard API
	redef var rotation_matrix = new Matrix[Float].identity(4)

	# Get the angle value from the `rotation_matrix`
	redef fun down_up
	do
		var a = rotation_matrix[0, 1]
		var b = rotation_matrix[1, 1]
		return -atan2(a, b)
	end

	# Get the angle value from the `rotation_matrix`
	redef fun left_right
	do
		var a = rotation_matrix[2, 0]
		var b = rotation_matrix[2, 2]
		return -atan2(a, b)
	end
end

redef class GammitApp
	# Use Cardboard's head tacking features
	var head_tracker: NativeHeadTracker

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

	private var java_rotation_matrix = new JavaFloatArray(16) is lazy

	redef fun frame_logic
	do
		# Extract rotation matrix from Cardboard
		head_tracker.last_head_view(java_rotation_matrix, 0)

		# Simple alias for shorter code
		var t = camera.rotation_matrix

		# Copy interesting values from the Java array to our matrix
		t[0, 0] = java_rotation_matrix[0]
		t[0, 1] = java_rotation_matrix[1]
		t[0, 2] = java_rotation_matrix[2]
		t[1, 0] = java_rotation_matrix[4]
		t[1, 1] = java_rotation_matrix[5]
		t[1, 2] = java_rotation_matrix[6]
		t[2, 0] = java_rotation_matrix[8]
		t[2, 1] = java_rotation_matrix[9]
		t[2, 2] = java_rotation_matrix[10]

		super
	end

	redef fun accept_event(event)
	do
		### Gamepad support


		### Mouse support (probably over bluetooth) for people without a compatible gamepad
		if event isa AndroidPointerEvent then
			if event.pressed then # TODO use just_wend_down
				# Move forward
				display.keys.downs.add "w"
			else # event.depressed
				if display.keys.downs.has("w") then display.keys.downs.remove "w"
			end
			return true
		else if event isa AndroidKeyEvent and event.is_down then
			if event.is_back_key then
				# place
				act(display.width/2, display.height/2, false)
				return true
			else if event.key_code == 125 then
				# mine
				act(display.width/2, display.height/2, true)
				return true
			end
		else if event isa AndroidKeyEvent and event.is_back_key then
			# Catch all back keys so it doesn't leave our app
			return true
		end

		return super
	end
end
