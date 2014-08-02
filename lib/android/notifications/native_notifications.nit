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

# Native Java classes for notifications
module native_notifications is min_api_version(11)

import android::assets_and_resources

in "Java" `{
	import android.content.Context;
	import android.app.NotificationManager;
	import android.app.Notification;
`}

redef class NativeActivity
	fun notification_manager: NativeNotificationManager in "Java" `{
		return (NotificationManager)recv.getSystemService(Context.NOTIFICATION_SERVICE);
	`}
end

extern class NativeNotificationManager in "Java" `{ android.app.NotificationManager `}

	fun notify(tag: JavaString, id: Int, notif: NativeNotification)
	in "Java" `{ recv.notify(tag, (int)id, notif); `}

	fun cancel(tag: JavaString, id: Int) in "Java" `{ recv.cancel(tag, (int)id); `}

	fun cancel_all in "Java" `{ recv.cancelAll(); `}
end

extern class NativeNotification in "Java" `{ android.app.Notification `}
end

extern class NativeNotificationBuilder in "Java" `{ android.app.Notification$Builder `}

	new (context: NativeActivity) in "Java" `{ return new Notification.Builder(context); `}

	fun create: NativeNotification in "Java" `{
		// deprecated since api 16, which introduce build()
		return recv.getNotification();
	`}

	fun title=(value: JavaString) in "Java" `{ recv.setContentTitle(value); `}

	fun text=(value: JavaString) in "Java" `{ recv.setContentText(value); `}

	fun ticker=(value: JavaString) in "Java" `{ recv.setTicker(value); `}
	
	fun small_icon=(value: Int) in "Java" `{ recv.setSmallIcon((int)value); `}
	
	#fun large_icon=(value: Int) in "Java" `{ recv.setLargeIcon(value); `}

	fun auto_cancel=(value: Bool) in "Java" `{ recv.setAutoCancel(value); `}

	fun number=(value: Int) in "Java" `{ recv.setNumber((int)value); `}

	fun ongoing=(value: Bool) in "Java" `{ recv.setOngoing(value); `}

	#fun progress(value, out_of: Int, indeterminate: Bool)
	#in "Java" `{ recv.setProgress(value, out_of, indeterminate); `}

	#fun sub_text=(value: JavaString) in "Java" `{ recv.setSubText(value); `}

	#fun show_when=(value: Bool) in "Java" `{ recv.setShowWhen(value); `}

	#fun add_action
end
