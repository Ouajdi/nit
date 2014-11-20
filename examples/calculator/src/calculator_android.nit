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

# Android calculator application
module calculator_android is
	app_name("app.nit Calc.")
	app_version(0, 1, git_revision)
	java_package("org.nitlanguage.calculator")
end

import android
import android::ui

import calculator_logic

redef class App
	var context = new CalculatorContext

	private var display: NativeEditText
	private var op2but = new HashMap[String, Button]

	var inited = false
	redef fun init_window
	do
		super

		if inited then return
		inited = true

		print "----------------- init window --------------"

		# Setup UI
		var context = native_activity
		var layout = new NativeLinearLayout(context)
		layout.set_vertical

		# Display screen
		var display = new NativeEditText(context)
		layout.add_view_with_weight(display, 1.0)
		display.text_size = 40.0
		self.display = display

		var ops = [["7", "8", "9", "+"],
		           ["4", "5", "6", "-"],
		           ["1", "2", "3", "*"],
		           ["0", ".", "C", "/"],
		           ["="]]

		# Buttons; numbers and operators
		for line in ops do
			var buts_layout = new NativeLinearLayout(context)
			buts_layout.set_horizontal
			layout.add_view_with_weight(buts_layout, 1.0)

			for op in line do
				var but = new Button(self)
				but.callback_to = self
				but.text = op
				but.native.text_size = 40.0
				buts_layout.add_view_with_weight(but.native, 1.0)
				op2but[op] = but
			end
		end

		context.content_view = layout
	end

	redef fun clicked2(event)
	do
		var sender = event.sender
		assert sender isa Button
		var op = sender.text
		
		if op == "." then
			op2but["."].native.enabled = false
			context.switch_to_decimals
		else if op.is_numeric then
			var n = op.to_i
			context.push_digit n
		else
			op2but["."].native.enabled = true
			context.push_op op.chars.first
		end

		display.text = context.display_text.to_java_string
	end
end
