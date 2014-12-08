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

#
module gammit

import standalone

import app

redef class App

	#
	var gammit: nullable GammitApp = null

	protected fun new_gammit_app: GammitApp do return new GammitApp

	#var display: nullable GammitDisplay = null

	redef fun window_created
	do
		super

		if gammit == null then
			var gammit = new_gammit_app
			self.gammit = gammit
			gammit.setup
		end
	end

	#
	fun loop_body
	do
		var gammit = self.gammit
		if gammit != null then
			gammit.frame_logic
			gammit.display.draw_all_the_things
			gammit.generate_events
		end
	end

	redef fun run
	do
		loop loop_body
	end

	#redef fun full_frame do if not paused then super
end

# TODO remove App::setup?
# TODO make Gammit::loop private?

app.setup
app.run
