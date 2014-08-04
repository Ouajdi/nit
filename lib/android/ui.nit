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

# Android UI services
module ui is min_api_version(14)

import native_app_glue

in "Java" `{
	import android.app.NativeActivity;

	import android.view.Gravity;
	import android.view.MotionEvent;
	import android.view.ViewGroup;
	import android.view.ViewGroup.MarginLayoutParams;

	import android.widget.Button;
	import android.widget.LinearLayout;
	import android.widget.GridLayout;
	import android.widget.PopupWindow;
	import android.widget.TextView;

	import java.util.concurrent.ConcurrentLinkedQueue;

	import android.R;
	import android.widget.ArrayAdapter;

	import java.lang.*;
	import java.util.*;
`}

in "Java in" `{
	static class AppNitEvent {
		AppNitEvent() {}
		int sender;
		int position;
	}
`}

extern class AppNitEvent in "Java" `{ Nit_ui$AppNitEvent `}
	fun sender: Object in "Java" `{ return recv.sender; `}
	fun position: Int in "Java" `{ return recv.position; `}
end

# Java `ConcurrentLinkedQueue` of Nit objects
extern class JavaConcurrentLinkedQueue in "Java" `{ java.util.concurrent.ConcurrentLinkedQueue<AppNitEvent> `}

	# Create a new instance
	new in "Java" `{ return new ConcurrentLinkedQueue<AppNitEvent>(); `}

	# Add a Nit object
	#fun add(e: Object) in "Java" `{ recv.add(new Integer(e)); `}

	# Is `self` empty?
	fun is_empty: Bool in "Java" `{ return recv.isEmpty(); `}

	# Pop an `Object` from 
	fun pop: AppNitEvent in "Java" `{ return recv.poll(); `}
end

# A `View` for Android
extern class NativeView in "Java" `{ android.view.View `}
	fun minimum_width=(val: Int) in "Java" `{ recv.setMinimumWidth((int)val); `}
	fun minimum_height=(val: Int) in "Java" `{ recv.setMinimumHeight((int)val); `}
end

extern class NativeViewGroup in "Java" `{ android.view.ViewGroup `}
	super NativeView

	fun add_view(view: NativeView) in "Java" `{ recv.addView(view); `}
end

extern class NativeLinearLayout in "Java" `{ android.widget.LinearLayout `}
	super NativeViewGroup

	new(context: NativeActivity) in "Java" `{ return new LinearLayout(context); `}

	fun set_vertical in "Java" `{ recv.setOrientation(LinearLayout.VERTICAL); `}
	fun set_horizontal in "Java" `{ recv.setOrientation(LinearLayout.HORIZONTAL); `}

	redef fun add_view(view) in "Java"
	`{
		MarginLayoutParams params = new MarginLayoutParams(
			LinearLayout.LayoutParams.MATCH_PARENT,
			LinearLayout.LayoutParams.WRAP_CONTENT);
		recv.addView(view, params);
	`}

	fun add_view_with_weight(view: NativeView, weight: Float)
	in "Java" `{
		recv.addView(view, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT, (float)weight));
	`}
end

extern class NativeGridLayout in "Java" `{ android.widget.GridLayout `}
	super NativeViewGroup

	new(context: NativeActivity) in "Java" `{ return new android.widget.GridLayout(context); `}

	fun row_count=(val: Int) in "Java" `{ recv.setRowCount((int)val); `}

	fun column_count=(val: Int) in "Java" `{ recv.setColumnCount((int)val); `}

	redef fun add_view(view) in "Java" `{ recv.addView(view); `}
end

extern class NativeListView in "Java" `{ android.widget.ListView `}
	super NativeViewGroup

	new(context: NativeActivity) in "Java" `{
		return new android.widget.ListView(context) {
		};
	`}

	fun set_callback_to(queue: JavaConcurrentLinkedQueue, sender_object: Object) in "Java" `{
		final ConcurrentLinkedQueue<AppNitEvent> final_queue = queue;
		final int final_sender_object = sender_object;

		recv.setOnItemClickListener( new android.widget.AdapterView.OnItemClickListener() {
			public void onItemClick(android.widget.AdapterView parent, android.view.View sender, int position, long id) {
				AppNitEvent nit_event = new AppNitEvent();
				nit_event.sender = final_sender_object;
				nit_event.position = position;
				final_queue.add(nit_event);
			}
		});
	`}

	fun adapter=(adapter: NativeArrayAdapter) in "Java" `{
		recv.setAdapter(adapter);
	`}
end

extern class JavaArrayListOfString in "Java" `{ java.util.ArrayList<String> `}
	type E: JavaString

	new in "Java" `{ return new ArrayList<String>(); `}
	fun add(e: E) in "Java" `{ recv.add(e); `}
	fun clear in "Java" `{ recv.clear(); `}
end

extern class NativeArrayAdapter in "Java" `{ android.widget.ArrayAdapter<java.lang.String> `}
	new(context: NativeActivity, array: JavaArrayListOfString) in "Java" `{
		return new ArrayAdapter<String>(context, android.R.layout.simple_list_item_1, array);
	`}

	fun notify_data_set_changed in "Java" `{
		final ArrayAdapter final_recv = recv;

		((NativeActivity)recv.getContext()).runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				final_recv.notifyDataSetChanged();
			}
		});
	`}
end

extern class NativePopupWindow in "Java" `{ android.widget.PopupWindow `}
	super NativeView

	new (context: NativeActivity) in "Java" `{
		PopupWindow recv = new PopupWindow(context);
		recv.setWindowLayoutMode(LinearLayout.LayoutParams.MATCH_PARENT,
			LinearLayout.LayoutParams.MATCH_PARENT);
		recv.setClippingEnabled(false);
		return recv;
	`}

	fun content_view=(layout: NativeViewGroup) in "Java" `{ recv.setContentView(layout); `}
end

redef extern class NativeActivity

	# Fill this entire `NativeActivity` with `popup`
	#
	# TODO replace NativeActivity by our own NitActivity
	fun dedicate_to_popup(popup: NativePopupWindow, popup_layout: NativeViewGroup) in "Java" `{
		final LinearLayout final_main_layout = new LinearLayout(recv);
		final ViewGroup final_popup_layout = popup_layout;
		final PopupWindow final_popup = popup;
		final NativeActivity final_recv = recv;

		recv.runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				MarginLayoutParams params = new MarginLayoutParams(
					LinearLayout.LayoutParams.MATCH_PARENT,
					LinearLayout.LayoutParams.MATCH_PARENT);

				final_recv.setContentView(final_main_layout, params);

				// Start loading the ad.
				final_popup.showAtLocation(final_popup_layout, Gravity.TOP, 0, 40);
			}
		});
	`}

	# This is a workaround for the use on `takeSurface` in `NativeActivity.java`
	#
	fun content_view=(layout: NativeViewGroup)
	do
		var popup = new NativePopupWindow(self)
		popup.content_view = layout
		dedicate_to_popup(popup, layout)
	end

	# This would be the right method to use, if...
	fun real_content_view=(layout: NativeViewGroup) in "Java" `{
		final ViewGroup final_layout = layout;
		final NativeActivity final_recv = recv;

		recv.runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				final_recv.setContentView(final_layout);

				final_layout.requestFocus();
			}
		});
	`}

	fun input_method_manager: NativeInputMethodManager in "Java" `{
		return (android.view.inputmethod.InputMethodManager)recv.getSystemService(android.content.Context.INPUT_METHOD_SERVICE);
	`}
end

extern class NativeTextView in "Java" `{ android.widget.TextView `}
	super NativeView

	new (context: NativeActivity) in "Java" `{ return new TextView(context); `}

	#fun text=(value: JavaString) in "Java" `{ recv.setText(value); `}
	fun text: JavaString in "Java" `{ return recv.getText().toString(); `}
	fun text=(value: JavaString) in "Java" `{

		final TextView final_recv = recv;
		final String final_value = value;

		((NativeActivity)recv.getContext()).runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				final_recv.setText(final_value);
			}
		});
	`}

	fun enabled: Bool in "Java" `{ return recv.isEnabled(); `}
	fun enabled=(value: Bool) in "Java" `{
		final TextView final_recv = recv;
		final boolean final_value = value;

		((NativeActivity)recv.getContext()).runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				final_recv.setEnabled(final_value);
			}
		});
	`}

	fun gravity_center in "Java" `{
		recv.setGravity(Gravity.CENTER);
	`}

	fun text_size=(dpi: Float) in "Java" `{
		recv.setTextSize(android.util.TypedValue.COMPLEX_UNIT_DIP, (float)dpi);
	`}
end

extern class NativeEditText in "Java" `{ android.widget.EditText `}
	super NativeTextView

	new (context: NativeActivity) in "Java" `{ return new android.widget.EditText(context); `}

	fun width=(val: Int) in "Java" `{ recv.setWidth((int)val); `}

	fun input_type_text in "Java" `{ recv.setInputType(android.text.InputType.TYPE_CLASS_TEXT); `}
end

extern class NativeButton in "Java" `{ android.widget.Button `}
	super NativeTextView

	new (context: NativeActivity, queue: JavaConcurrentLinkedQueue, sender_object: Object)
	in "Java" `{
		final ConcurrentLinkedQueue<AppNitEvent> final_queue = queue;
		final int final_sender_object = sender_object;

		return new Button(context){
			@Override
			public boolean onTouchEvent(MotionEvent event) {
				if(event.getAction() == MotionEvent.ACTION_DOWN) {
					AppNitEvent nit_event = new AppNitEvent();
					nit_event.sender = final_sender_object;
					final_queue.add(nit_event);
					return true;
				}
				return false;
			}
		};
	`}
end

extern class NativeWebView in "Java" `{ android.webkit.WebView `}
	super NativeView

	# To execute on main thread
	new (context: NativeActivity) in "Java" `{ return new android.webkit.WebView(context); `}

	fun load_url(url: JavaString) in "Java" `{ recv.loadUrl(url); `}

	fun load_data(html, content_type: JavaString) in "Java" `{ recv.loadData(html, content_type, null); `}
end

extern class NativeInputMethodManager in "Java" `{ android.view.inputmethod.InputMethodManager `}
	fun is_active: Bool in "Java" `{ return recv.isActive(); `}

	fun show(view: NativeView) in "Java" `{
		final android.view.inputmethod.InputMethodManager final_recv = recv;
		final android.view.View final_view = view;

		((NativeActivity)view.getContext()).runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				final_recv.showSoftInput(final_view, 0);
			}
		});
	`}
end

class Button
	var native: NativeButton

	var callback_to: UICallback = app is lazy, writable

	init(app: App)
	do
		self.native = new NativeButton(app.native_activity, app.ui_queue, self)
	end

	fun text: String do return native.text.to_s
	fun text=(value: Text) do native.text = value.to_s.to_java_string
end

class ListView
	var native: NativeListView
	var adapter: NativeArrayAdapter
	var array: JavaArrayListOfString

	init
	do
		native = new NativeListView(app.native_activity)
		array = new JavaArrayListOfString
		adapter = new NativeArrayAdapter(app.native_activity, array)
		native.adapter = adapter
		native.set_callback_to(app.ui_queue, self)
	end

	fun on_click
	do
	end
end

#class FileList
#end

interface UICallback
	fun clicked(sender: AppNitEvent) do end
end

redef class App
	super UICallback

	var ui_queue = new JavaConcurrentLinkedQueue is lazy

	protected fun loop_on_ui_callbacks
	do
		var queue = ui_queue
		if queue != null then
			while not queue.is_empty do
				var e = queue.pop
				var sender = e.sender
				if sender isa Button then sender.callback_to.clicked(e)
				if sender isa ListView then app.clicked(e)
			end
		end
	end

	redef fun run
	do
		loop
			poll_looper 100
			loop_on_ui_callbacks
		end
	end
end
