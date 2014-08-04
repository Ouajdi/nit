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
module android_ui is
	app_name("app.nit UI test")
	app_version(0, 1, git_revision)
	java_package("org.nitlanguage.android_ui")
	android_manifest("""<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>""")
end

import android
import android::ui
import android::toast
import android::notifications

redef class App

	var but_notif: Button
	var but_toast: Button

	var notif: nullable Notification = null

	var inited = false
	redef fun init_window
	do
		super

		if inited then return
		inited = true

		# Setup UI
		var context = native_activity
		var layout = new NativeLinearLayout(context)
		layout.set_vertical

		but_notif = new Button(self)
		but_notif.text = "Show Notification"
		layout.add_view but_notif.native

		but_toast = new Button(self)
		but_toast.text = "Show Toast"
		layout.add_view but_toast.native

		#but_files = new Button(self)
		#but_files.text = "Show Notification"
		#layout.add_view but_files.native

		files_list = new ListView
		layout.add_view files_list.native

		context.content_view = layout

		update_files
	end

	var files_list: ListView
	var dir = "/"
	var files_cache = new Array[String]

	fun update_files
	do
		print "update files"
		files_list.array.clear
		print "update files b"
		files_cache.clear
		print "update files c {dir}"
		if dir.simplify_path != "/" then
			files_list.array.add "..".to_java_string
			files_cache.add ".."
		end
		for file in dir.files do
			files_list.array.add file.to_java_string
			files_cache.add file
		end
		files_list.adapter.notify_data_set_changed
		print "update files e"
	end

	fun view_file(file: String)
	do
		var path = dir.join_path(file)
		if path.file_stat.is_dir then
			self.dir = path
			update_files
		else
			var ext = path.file_extension
			intent_hack(native_activity, ext.to_java_string, path.to_java_string)
		end
	end

	fun intent_hack(context: NativeActivity, ext, path: JavaString) in "Java" `{
		java.io.File file = new java.io.File(path);

		java.lang.String mime =	android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext);

		android.content.Intent intent = new android.content.Intent();
		intent.setAction(android.content.Intent.ACTION_VIEW);
		intent.setDataAndType(android.net.Uri.fromFile(file), mime);
		context.startActivityForResult(intent, 10);
	`}

	fun act_notif
	do
		var notif = self.notif
		if notif == null then
			notif = new Notification
			notif.title = "From Nit"
			notif.text = "lorem ipsum"
			notif.ticker = "Ticker text..."
			notif.show
			self.notif = notif
		else
			assert notif.is_shown
			notif.cancel
			self.notif = null
		end
	end

	fun act_toast
	do
		toast("Sample toast from app.nit at {get_time}", false)
	end

	redef fun clicked(event)
	do
		var sender = event.sender
		if sender isa Button then
			if sender == but_notif then
				act_notif
			else if sender == but_toast then
				act_toast
			end
		else if sender isa ListView then
			var selection = files_cache[event.position]
			view_file selection
		end
	end
end
