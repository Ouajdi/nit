# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2011-2014 Alexis Laferrière <alexis.laf@xymus.net>
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

# Offers contextual controls (right-click menu)
module contextual

import controls

# An entry to the ContextualMenu
class ContextualControl
	super TextRectangleButton

	init (receiver: HitReceiver, text: String, font: Font)
	do
		super(receiver, 0, 0, 120, 20, text, font)
	end
end

# A submenu to ContextualMenu
class ContextualSubmenu
	super ContextualControl

	var submenu: ContextualMenu
	var opened: Bool writable = false

	init (receiver: HitReceiver, sm: ContextualMenu, text: String, font: Font)
	do
		super(receiver, text, font)

		submenu = sm
	end

	redef fun input(screen, event)
	do
		if super then
			if event isa PointerEvent and event.depressed then
				opened = not opened
				submenu.top = top
				submenu.left = right
			end
			return true
		else
			return submenu.input(screen, event)
		end
	end

	redef fun draw(display)
	do
		super

		if opened then submenu.draw(display)
	end
end

# The right-click menu itself
class ContextualMenu
	super RectangleMenu
	super List[ContextualControl]

	init do super

	redef fun clear
	do
		for sm in self do if sm isa ContextualSubmenu then sm.opened = false
		super
	end
end

