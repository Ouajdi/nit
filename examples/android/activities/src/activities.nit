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

module activities is
	app_name("app.nit Activities")
	app_version(0, 1, git_revision)
	java_package("org.nitlanguage.android_activities")
	extra_java_files("OtherActivity.java", "AppNitNativeActivity.java")
	min_api(19)
	android_manifest_application("""
	<activity
		android:name="org.nitlanguage.android_activities.OtherActivity"
		android:label="@string/app_name">
		<meta-data android:name="org.nitlanguage.android_activities"
			android:value="OtherActivity" />
	</activity>
	<activity
		android:name=".OtherActivity"
		android:label="@string/app_name">
		<meta-data android:name="org.nitlanguage.android_activities"
			android:value="OtherActivity" />
	</activity>
""")
end

import mnit_android

in "Java" `{

	//package org.nitlanguage.android_ui;

	import android.content.Intent;
	import android.widget.Toast;
	import org.nitlanguage.android_activities.OtherActivity;

	import android.app.NativeActivity;
`}

extern class AppNitNativeActivity in "Java" `{ org.nitlanguage.android_activities.AppNitNativeActivity `}
	super NativeActivity
end

redef class App
	redef fun frame_core(display)
	do
		display.clear(1.0, 0.0, 0.0)
	end

	redef fun input(ie)
	do
		if ie isa PointerEvent and ie.depressed then
			launch_activity
			return true
		else if ie isa QuitEvent then
			quit = true
			return true
		else
			print "unknown input: {ie}"
			return false
		end
	end

	fun launch_activity import native_activity in "Java" `{
		final android.app.NativeActivity context = App_native_activity(recv);

		context.runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				Intent intent = new Intent(context, OtherActivity.class);
				context.startActivity(intent);
			}
		});
	`}
end
