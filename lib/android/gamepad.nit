# This file is part of NIT (http://www.nitlanguage.org).
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
module gamepad

import input_events

redef class AndroidKeyEvent

	# Did the A button raise `self`?
	fun is_a: Bool do return key_code == 96

	# Did the B button raise `self`?
	fun is_b: Bool do return key_code == 97

	# Did the X button raise `self`?
	fun is_x: Bool do return key_code == 99

	# Did the Y button raise `self`?
	fun is_y: Bool do return key_code == 100

	fun is_dpad: Bool do return is_dpad_up or is_dpad_down or is_dpad_left or is_dpad_right
	fun is_dpad_up: Bool do return key_code == 19
	fun is_dpad_down: Bool do return key_code == 20
	fun is_dpad_left: Bool do return key_code == 21
	fun is_dpad_right: Bool do return key_code == 22

	# Did the start button raise `self`?
	fun is_start: Bool do return key_code == 108

	# Did the select button raise `self`?
	fun is_select: Bool do return key_code == 109

	fun is_rb: Bool do return key_code == 103
	fun is_rt: Bool do return key_code == 105
	fun is_lb: Bool do return key_code == 102
	fun is_lt: Bool do return key_code == 101

	fun is_media_back: Bool do return key_code == 87
	fun is_media_pause: Bool do return key_code == 85
	fun is_media_next: Bool do return key_code == 88
end
