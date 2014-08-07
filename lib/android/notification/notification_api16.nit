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

module notification_api16 is min_api_version 16

intrude import notification_api14
intrude import notification
import standard

in "Java" `{
	//import java.lang.*;
`}

private extern class NotificationStyle in "Java" `{ android.app.Notification$Style `}
end

private extern class InboxStyle in "Java" `{ android.app.Notification$InboxStyle `}
	super NotificationStyle

	new in "Java" `{ return new android.app.Notification.InboxStyle(); `}
	fun add_line(line: JavaString) in "Java" `{ recv.addLine(line); `}
	fun summary_text=(summary: JavaString) in "Java" `{ recv.setSummaryText(summary); `}
end

redef extern class NativeNotificationBuilder
	private fun style=(style: NotificationStyle) in "Java" `{ recv.setStyle(style); `}

	#redef fun create do return build

	#fun build: NativeNotification in "Java" `{  `}

	fun progress(value, out_of: Int, indeterminate: Bool) in "Java" `{
		recv.setProgress((int)value, (int)out_of, indeterminate);
	`}

	fun sub_text=(value: JavaString) in "Java" `{ recv.setSubText(value); `}

	#fun add_action
end

redef class Notification
	redef fun big_text_intern(builder, text, summary)
	do
		var style = new InboxStyle
		for line in text.split("\n") do style.add_line(line.to_java_string)
		if summary != null then style.summary_text = summary.to_java_string
		builder.style = style
	end
end
