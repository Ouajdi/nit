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
module benitlux_android is
	app_name("Benitlux")
	app_version(0, 1, git_revision)
	java_package("org.nitlanguage.benitlux_android")
	android_manifest("""<uses-permission android:name="android.permission.INTERNET" />""")

	extra_java_files("NitService1.java")
	android_manifest_application("""<service android:name=".NitService1" ></service>""")
end

import app::data_store
import android::android_data_store

#import android::
import android::ui
import android::notification
import android::notification::notification_api16
import wifi
import pthreads

import json_serialization

import benitlux_model

in "Java" `{
	import org.apache.http.client.methods.HttpGet;
	import org.apache.http.impl.client.DefaultHttpClient;
	import org.apache.http.HttpResponse;
	import org.apache.http.HttpStatus;
	import org.apache.http.StatusLine;
	import java.io.ByteArrayOutputStream;

	import android.app.Service;
	import android.content.Intent;
	import android.os.IBinder;



	// for test_listener
	import android.app.Notification;
	import android.app.NotificationManager;
	import android.app.TaskStackBuilder;
	import android.content.BroadcastReceiver;
	import android.content.ContentResolver;
	import android.content.Context;
	import android.content.Intent;
	import android.content.IntentFilter;
	import android.database.ContentObserver;
	import android.net.NetworkInfo;
	import android.net.wifi.ScanResult;
	import android.net.wifi.WifiManager;
	import android.os.Handler;
	import android.os.Message;
	import android.provider.Settings;
`}

redef fun print(txt) do super

redef class DataStore
	fun last_visit_date: nullable String do return self["last_visit_date"].as(nullable String)
	fun last_visit_date=(v: nullable String) do self["last_visit_date"] = v

	fun before_last_visit_date: nullable String do return self["before_last_visit_date"].as(nullable String)
	fun before_last_visit_date=(v: nullable String) do self["before_last_visit_date"] = v
end

redef class Activity
	super EventCatcher

	fun start_service(context: NativeContext) in "Java" `{
		
			int id = android.os.Process.myPid();
			android.util.Log.w("------- gui -", String.valueOf(id));
		context.startService(new android.content.Intent(context, org.nitlanguage.benitlux_android.NitService1.class));
	`}

	var but_query: Button
	var but_at_ben: Button
	var but_test_diff: Button
	var but_test_service: Button
	var but_test_wifi: Button

	var notif: nullable Notification = null

	var inited = false
	redef fun on_create(state)
	do
		super

		if inited then return
		inited = true

		# Setup UI
		var context = native
		var layout = new NativeLinearLayout(context)
		layout.set_vertical

		but_query = new Button
		but_query.text = "Quoi de neuf?"
		but_query.event_catcher = self
		layout.add_view but_query.native

		but_at_ben = new Button
		but_at_ben.text = "J'y suis!"
		but_at_ben.event_catcher = self
		layout.add_view but_at_ben.native

		but_test_diff = new Button
		but_test_diff.text = "Test diff"
		but_test_diff.event_catcher = self
		layout.add_view but_test_diff.native

		but_test_service = new Button
		but_test_service.text = "Test service"
		but_test_service.event_catcher = self
		layout.add_view but_test_service.native

		but_test_wifi = new Button
		but_test_wifi.text = "Test wifi"
		but_test_wifi.event_catcher = self
		layout.add_view but_test_wifi.native

		beers_list = new ListView
		beers_list.event_catcher = self
		layout.add_view beers_list.native

		context.content_view = layout
	end

	#
	var beers_list: ListView

	fun check_beers
	do
		# Get date of last visit
		var last_date = app.data_store.last_visit_date
		if last_date != null and last_date == today then
			# Last date has been updated today
			last_date = app.data_store.before_last_visit_date
		end

		# No date reference, use today so we don't have changes
		if last_date == null then last_date = today

		check_beers_since last_date
	end

	fun check_beers_test do check_beers_since "2014-07-28"

	fun check_beers_since(date: String)
	do
		print "-------- check beers since {date}"
		var notif = self.notif
		if notif == null then notif = new Notification(null, null)

		var r = hack_webrequest("http://benitlux.xymus.net/rest/since/{date}".to_java_string).to_s
		print "-- a"
		var events: nullable BeerEvents = null

		if not r.is_empty and r.chars.first == '{' then
			var deserializer = new JsonDeserializer(r)
			events = deserializer.deserialize.as(nullable BeerEvents)
		end
		print "-- b"

		var ticker
		if not events.new_beers.is_empty then
			var beer_names = new Array[String]
			for beer in events.new_beers do beer_names.add beer.name
			ticker = "Benitlux, new beers: {beer_names.join(", ")}"
		else ticker = "Benitlux (no change)"
		print "-- c"

		if events == null then return

		var content = events.to_email_content
		print "-- d"

		# Notification
		notif.title = "Changes since {date}"
		print "-- 1"
		notif.text = content.join("\n")
		print "-- 2"
		notif.big_text = content.join("\n")
		print "-- 3"
		#notif.big_text_summary = "changes since {date}"
		notif.ticker = ticker
		print "-- 4"
		notif.show
		print "-- 5"
		self.notif = notif
		print "-- e"

		# NativeListView
		beers_list.array.clear
		for line in content do beers_list.array.add line.to_java_string
		beers_list.adapter.notify_data_set_changed
	end

	fun hack_webrequest(uri: JavaString): JavaString in "Java" `{
		try {
			DefaultHttpClient client = new DefaultHttpClient();
			HttpGet get = new HttpGet(uri);
			HttpResponse res = client.execute(get);
			StatusLine line = res.getStatusLine();

			if(line.getStatusCode() == HttpStatus.SC_OK){
					ByteArrayOutputStream out = new ByteArrayOutputStream();
				res.getEntity().writeTo(out);
				out.close();
				return out.toString();
			} else {
				res.getEntity().getContent().close();
				return "not ok";
			}
		} catch (Exception ex) {
				return ex.getMessage();
		}
	`}

	fun update_last_visit
	do
		var today = today

		var last_visit_date = app.data_store.last_visit_date
		if last_visit_date == today then return

		if last_visit_date != null then
			# push back
			app.data_store.before_last_visit_date = last_visit_date
		end
		app.data_store.last_visit_date = today
	end

	fun today: String
	do
		var tm = new Tm.localtime
		return "{tm.year+1900}-{tm.mon+1}-{tm.mday}"
	end

	fun test_service
	do
		print "------ start service"
		start_service native

		test_listener native
	end

	fun test_listener(context: NativeContext) in "Java" `{
		IntentFilter filter = new IntentFilter();
		filter.addAction(WifiManager.WIFI_STATE_CHANGED_ACTION);
		filter.addAction(WifiManager.NETWORK_STATE_CHANGED_ACTION);
		filter.addAction(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION);

		NetworkInfo mNetworkInfo;

		context.registerReceiver(
			new BroadcastReceiver() {
				@Override
				public void onReceive(Context context, Intent intent) {
					if (intent.getAction().equals(WifiManager.WIFI_STATE_CHANGED_ACTION)) {
						android.util.Log.w("Nit", ">>>>> wifi state changed action");
						//mWifiState = intent.getIntExtra(WifiManager.EXTRA_WIFI_STATE,
							//WifiManager.WIFI_STATE_UNKNOWN);
						//resetNotification();
					} else if (intent.getAction().equals(
						WifiManager.NETWORK_STATE_CHANGED_ACTION)) {

						//mNetworkInfo = (NetworkInfo) intent.getParcelableExtra(
						//	WifiManager.EXTRA_NETWORK_INFO);

						// reset & clear notification on a network connect & disconnect
						//switch(mNetworkInfo.getDetailedState()) {
							//case CONNECTED:
							//case DISCONNECTED:
							//case CAPTIVE_PORTAL_CHECK:
								//resetNotification();
							//break;
						//}
						android.util.Log.w("Nit", ">>>>> network state changed action");
					} else if (intent.getAction().equals(
						WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)) {

						android.util.Log.w("Nit", ">>>>> scan result available");

						//checkAndSetNotification(mNetworkInfo,
						//	mWifiStateMachine.syncGetScanResultsList());
					}
				}
			}, filter);
	`}

	fun test_wifi
	do
		print "--------- test wifi"
		var wifi = app.wifi_manager
		
		beers_list.array.clear

		var is_on = wifi.is_wifi_enabled
		beers_list.array.add is_on.to_s.to_java_string

		var networks = wifi.get_scan_results
		var found_ben = false
		for i in networks.length.times do
			var net = networks[i]
			beers_list.array.add net.ssid
			beers_list.array.add net.bssid
			if net.ssid.to_s == "BENELUX1" and
				net.bssid.to_s == "C8:F7:33:81:B0:E6" then
				found_ben = true
			end
		end
		if found_ben then beers_list.array.add "Ben found!".to_java_string

		beers_list.adapter.notify_data_set_changed
	end

	redef fun catch_event(event)
	do
		if not event isa ClickEvent then return

		var sender = event.sender
		#if sender isa Button then
			if sender == but_query then
				check_beers
			else if sender == but_at_ben then
				update_last_visit
			else if sender == but_test_diff then
				check_beers_test
			else if sender == but_test_service then
				test_service
			else if sender == but_test_wifi then
				test_wifi
			end
		#else if sender isa NativeListView then
			#var selection = files_cache[event.position]
			#view_file selection
			#end
	end
end
