# This file is part of NIT ( http://www.nitlanguage.org ).
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
module game

import android
import ui

redef class App

	# Queue of events to be received by the main thread
	var event_queue = new ConcurrentList[AppEvent]

	# Call `react` on all `AppEvent` available in `event_queue`
	protected fun loop_on_ui_callbacks
	do
		var queue = event_queue
		while not queue.is_empty do
			var event = queue.pop
			event.react
		end
	end
end

redef class NativeActivity
	private fun take_surface in "Java" `{
		recv.getWindow().takeSurface(new SurfaceHolder.Callback2(){
			@Override
			public abstract void surfaceRedrawNeeded (SurfaceHolder holder) {
			}
		});
	`}
end

#
class GameActivity
	super Activity

	# TODO on_create thread
	# TODO event queue

	# Is the application currently paused?
	var paused = true

	redef fun on_pause
	do
		paused = true
		super
	end

	redef fun on_resume
	do
		paused = false
		super
	end

	redef fun on_window_focus_changed(has_focus)
	do
		paused = not has_focus
		super
	end

	redef fun on_destroy do exit_thread(0)
end
