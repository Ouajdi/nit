# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2011-2014 Alexis Laferrière <alexis.laf@xymus.net>
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

# Provides controls bases for mnit display system
module controls

import mnit_display
import mnit_input

# General control class
class Control
	# draw control
	fun draw(display: Display) do end

	# try to accept input
	# returns true if intercepted
	fun input(screen: Screen, event: InputEvent): Bool do return false
end

# Clickable control
class PointerControl
	super Control

	# event is within control
	fun within(event: PointerEvent): Bool is abstract
end

# Selectable control to catch keyboard inputs
class SelectableControl
	super Control

	var selected: Bool = false
	
	fun select(screen: Screen)
	do
		if screen.selected != null then screen.selected.selected = false
		
		selected = true
		screen.selected = self
	end
	
	fun unselect(screen: Screen)
	do
		if screen.selected != null
		then
			screen.selected.selected = false
		end
		
		selected = false
		screen.selected = null
	end
end

# Control holding other controls
class ContainerControl
	super Control
	super List[Control]
	
	init do end

	redef fun draw(display)
	do
		for control in self
		do
			control.draw(display)
		end
	end
	
	redef fun input(screen, event)
	do
		var intercepted: Bool = false
		for control in self
		do
			if control.input(screen, event) then
				intercepted = true
				break
			end
		end
		
		return intercepted
	end
end

# Control to manage a whole screen
class Screen
	super ContainerControl

	# which (if any) selectable control is selected
	var selected: nullable SelectableControl = null
end

class ButtonColumn
	super ContainerControl
end

# Receiver called by controls when activated by an input event
# Each button is associated with one HitReceiver
interface HitReceiver
	fun hit(sender: Control, event: InputEvent) is abstract
end

# HitReceiver collection
class MultipleHitReceiver
	super HitReceiver
	super List[HitReceiver]

	init (receivers: HitReceiver ...) do from(receivers)
	redef fun hit(sender, event) do for r in self do r.hit(sender, event)
end

# Control activated by a pointer event
class Button
	super PointerControl

	var receiver: HitReceiver
	
	init init_button(receiver: HitReceiver) do self.receiver = receiver

	fun on_click(event: InputEvent) do receiver.hit(self, event)
	
	redef fun input(screen, event)
	do
		if event isa PointerEvent and within(event) then
			if event.depressed then on_click(event)
			return true
		end
		
		return false
	end
end

# Precise key listener but invisible control
class KeyCatcher
	super Control

	var receiver: HitReceiver
	var keys: Array[String] # TODO change to char
	
	init (receiver: HitReceiver, keys: Array[String])
	do
		self.receiver = receiver
		self.keys = keys
	end
	
	redef fun input(screen, event)
	do
		if event isa KeyEvent and event.to_c != null and keys.has(event.to_c.to_s) then
			receiver.hit(self, event)
			return true
		end
		
		return false
	end
end

class RectangleControl
	super PointerControl

	var top: Int writable = 0
	var left: Int writable = 0
	var width: Int = 0
	var height: Int = 0
	
	fun right: Int do return left + width
	fun right=(v: Int) do width = v-left
	fun bottom: Int do return top + height
	fun bottom=(v: Int) do height = v-top
	
	fun center_x: Int do return left + width / 2
	fun center_y: Int do return top + height / 2
	
	init init_rectangle(l, t, w, h: Int)
	do
		top = t
		left = l
		width = w
		height = h
	end
	
	redef fun within(event)
	do
		return event.y.to_i > top and event.y.to_i < bottom and
				event.x.to_i > left and event.x.to_i < right
	end

	fun draw_back(display: Display) do end

end

class RectangleButton
	super Button
	super RectangleControl

	init init_rectangle(receiver: HitReceiver, l, t, w, h: Int)
	do
		init_button(receiver)
		super(l, t, w, h)
	end
end

# Vertical list of controls
class RectangleMenu
	super RectangleControl
	super ContainerControl

	var padding: Int = 8

	init
	do
		init_rectangle(padding, padding, padding*2, padding)
		
		top = 0
		left = 0
	end
	
	redef fun top=(t: Int)
	do
		var d = t - top
		for c in self do c.top += d
		
		super
	end
	
	redef fun left=(l: Int)
	do
		var d = l - left
		for c in self do c.left += d 
	
		super
	end

	redef fun add(ctrl)
	do
		assert ctrl isa RectangleControl

		insert_in_menu(ctrl)
		
		super
	end
	
	# adapts current control size to all buttons
	# adpts button top left to this control
	protected fun insert_in_menu(ctrl: RectangleControl)
	do
		ctrl.top = bottom
		ctrl.left = left + padding
		
		height += ctrl.height + padding
		
		if width < ctrl.width + 2*padding
		then
			width = ctrl.width + 2*padding
		end
	end
	
	redef fun clear
	do
		height = padding
		
		super
	end
	
	redef fun draw(display)
	do
		super
		
		draw_back(display)
		
		# TODO
		# below is a hack
		# should be handled by a call to super:(
		for control in self do control.draw(display)
	end
	
	redef fun input(screen, event)
	do
		# var intercepted = super # TODO a call to super should work here

		var intercepted: Bool = false
		for control in self do if control.input(screen, event) then
			intercepted = true
			break
		end
		
		if not intercepted and event isa PointerEvent and within(event) then
			intercepted = true
		end
		
		return intercepted
	end
end

class HorizontalMenu
	super RectangleMenu

	init
	do
		init_rectangle(padding, padding, padding, padding*2)
	end

	redef fun insert_in_menu(ctrl: RectangleControl)
	do
		ctrl.top = top + padding
		ctrl.left = right
		
		width += ctrl.width + padding
		
		if height < ctrl.height + 2*padding then
			height = ctrl.height + 2*padding
		end
	end
	
	redef fun clear
	do
		width = padding
		
		super
	end
end

class TextRectangleButton
	super RectangleButton

	var text: String writable
	var font: Font
	
	init (receiver: HitReceiver, l, t, w, h: Int, text: String, font: Font)
	do
		init_rectangle(receiver, l, t, w, h)
		
		self.font = font
		self.text = text
	end
	
	redef fun draw(display)
	do
		draw_back(display)
		display.write(text, font, left+8, top+16)
	end
end

# Control to input text with the keyboard
class TextInputControl
	super RectangleControl
	super SelectableControl

	var label_text: String
	
	var input_img: nullable Image = null
	var input_text: String = ""
	
	var font: Font
	
	var receiver: HitReceiver
	
	var padding: Int = 8
	
	init (receiver: HitReceiver, l, t, w, h: Int, label_text: String, font: Font)
	do
		init_rectangle(l, t, w, h)
		
		self.font = font
		self.receiver = receiver
		self.label_text = label_text
	end
	
	fun text: String do return input_text
	fun text= (t: String)
	do
		input_text = t
		input_img = null
	end
	
	private fun visible_text: String do return input_text
	
	redef fun draw(display)
	do
		draw_back(display)

		display.write(label_text, font, left+8, top+16)

		if not input_text.is_empty then
			display.write(visible_text, font, left+16, top+32)
		end
	end
	
	redef fun input(screen, event)
	do
		if event isa KeyEvent then
			if selected then
				if not event.is_down then
					var c = event.to_c
					if c != null then
						var key = c.to_s
						if key.length == 1 then
							var char = key[0]
							if accepts_char(char) then
								text = input_text + key
							end
						else if key == "enter" then
							receiver.hit(self, event)
						else if key == "backspace" then
							if not text.is_empty then
								text = input_text.substring(0, input_text.length-1)
							end
						end
					end
				end

				return true
			end
		else if event isa PointerEvent then
			if within(event) then
				select(screen)
				return true
			end
		end
		
		return false
	end
	
	# is this a recognized character?
	fun accepts_char(char: Char): Bool
	do
		return char >= ' ' and char <= '~'
	end
end

# Hidden text input
class PasswordInputControl
	super TextInputControl

	init (receiver: HitReceiver, l, t, w, h: Int, label_text: String, font: Font)
	do
		super
	end
	
	redef fun visible_text do return "*" * input_text.length
end

# Text input limited to numbers
class NumberInputControl
	super TextInputControl

	init (receiver: HitReceiver, l, t, w, h: Int, label_text: String, font: Font)
	do
		super
	end
	
	redef fun accepts_char(char) do return char >= '0' and char <= '9'
	
	fun number: nullable Int
	do
		if input_text.is_empty then
			return null
		else
			return input_text.to_i
		end
	end
end

# Simple separator control (mainly for RectangleMenu and HorizontalMenu)
class SeparatorControl
	super RectangleControl

	init (l, t, w, h: Int)
	do
		init_rectangle(l, t, w, h)
	end
	
	redef fun draw(display)
	do
		draw_back(display)
	end
end

# Basic rectangle button using an image
class ImageRectangleButton
	super RectangleButton

	var img: Image
	
	init (receiver: HitReceiver, l, t, w, h: Int, img: Image)
	do
		init_rectangle(receiver, l, t, w, h)
		
		self.img = img
	end
	
	redef fun draw(display)
	do
		var t = top.to_f
		var b = bottom.to_f
		var l = left.to_f
		var r = right.to_f

		display.blit_stretched(img, l, b, l, t, r, t, r, b)
		
		super
	end
end
