# This file is part of NIT (http://www.nitlanguage.org).
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

# Services to show notification in the Android status bar
#
# ~~~~
# # Create and show a notification
# var notif = new Notification
# notif.title = "My Title"
# notif.text = "Some content"
# notif.ticker = "Ticker text"
# notif.show
#
# # Update the notification
# notif.text = "New content!"
# notif.ongoing = true # Make it un-dismissable
# nofif.show
#
# # Hide the notification
# notif.cancel
# ~~~~
#
# For more information, see:
# http://developer.android.com/guide/topics/ui/notifiers/notifications.html
module notifications

import standard
private import native_notifications

class Notification
	# Title of this notification (Mandatory)
	var title: nullable Text = null is writable

	# Text content (Mandatory)
	var text: nullable Text = null is writable

	# Text to show in the bar as the notification appears
	var ticker: nullable Text = null is writable

	# Name of a resource found in the `res/drawable-*` folders to use for the small icon
	#
	# By default, we use the app's icon, named "icon". A valid icon must be used
	# to display notifications.
	var small_icon: nullable Text = null is writable

	# Number to display on the bottom right part of the notification
	var number: nullable Int = null is writable

	# Is this notification ongoing? Not user dismissable.
	var ongoing: Bool = false is writable

	private var id: nullable Int = null
	private var tag = "app.nit notification"

	# Show the notification
	fun show
	do
		sys.jni_env.push_local_frame(8)

		var context = app.native_activity
		var builder = new NativeNotificationBuilder(context)

		# If no custom icon is specified, use app's
		var small_icon = self.small_icon
		if small_icon == null then small_icon = "icon"
		var small_icon_id = app.resource_manager.other_id(small_icon.to_s, "drawable")
		builder.small_icon = small_icon_id

		# Other options
		if title != null then builder.title = title.to_java_string
		if text != null then builder.text = text.to_java_string
		if ticker != null then builder.ticker = ticker.to_java_string
		builder.ongoing = ongoing

		var notif = builder.create
		var manager = context.notification_manager

		var id = self.id
		if id == null then id = sys.notification_id
		manager.notify(tag.to_java_string, id, notif)

		self.id = id

		sys.jni_env.pop_local_frame
	end

	fun is_shown: Bool do return id != null

	# require: `is_showing`
	fun cancel
	do
		sys.jni_env.push_local_frame(8)

		var id = self.id
		if id != null then
			var manager = app.native_activity.notification_manager
			manager.cancel(tag.to_java_string, id)

			self.id = null
		end

		sys.jni_env.pop_local_frame
	end
end

redef class Sys
	private var notification_id_cache = 0
	private fun notification_id: Int
	do
		var id = notification_id_cache
		notification_id_cache = id + 1
		return id
	end
end
