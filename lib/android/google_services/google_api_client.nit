# This file is part of NIT (http://www.nitlanguage.org).
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

# This code has been generated using `jwrapper`
module google_api_client

import mnit_android
import android::bundle

extern class NativeGoogleApiClient in "Java" `{ com.google.android.gms.common.api.GoogleApiClient `}
	super JavaObject

#	fun looper: NativeLooper  in "Java" `{
#		recv.getLooper();
#	`}
	fun connect in "Java" `{
		recv.connect();
	`}
#	fun blocking_connect0: NativeConnectionResult  in "Java" `{
#		recv.blockingConnect();
#	`}
#	fun blocking_connect1(arg0: Int, arg1: NativeTimeUnit): NativeConnectionResult  in "Java" `{
#		recv.blockingConnect(arg0, arg1);
#	`}
	fun disconnect in "Java" `{
		recv.disconnect();
	`}
	fun reconnect in "Java" `{
		recv.reconnect();
	`}
#	fun stop_auto_manage(arg0: NativeFragmentActivity) in "Java" `{
#		recv.stopAutoManage(arg0);
#	`}
	fun is_connected: Bool  in "Java" `{
		return recv.isConnected();
	`}
	fun is_connecting: Bool  in "Java" `{
		return recv.isConnecting();
	`}
	fun register_connection_callbacks(arg0: NativeGoogleApiClientConnectionCallbacks) in "Java" `{
		recv.registerConnectionCallbacks(arg0);
	`}
	fun is_connection_callbacks_registered(arg0: NativeGoogleApiClientConnectionCallbacks): Bool  in "Java" `{
		recv.isConnectionCallbacksRegistered(arg0);
	`}
	fun unregister_connection_callbacks(arg0: NativeGoogleApiClientConnectionCallbacks) in "Java" `{
		recv.unregisterConnectionCallbacks(arg0);
	`}
	fun register_connection_failed_listener(arg0: NativeGoogleApiClientOnConnectionFailedListener) in "Java" `{
		recv.registerConnectionFailedListener(arg0);
	`}
	fun is_connection_failed_listener_registered(arg0: NativeGoogleApiClientOnConnectionFailedListener): Bool  in "Java" `{
		recv.isConnectionFailedListenerRegistered(arg0);
	`}
	fun unregister_connection_failed_listener(arg0: NativeGoogleApiClientOnConnectionFailedListener) in "Java" `{
		recv.unregisterConnectionFailedListener(arg0);
	`}
end

extern class NativeGoogleApiClientConnectionCallbacks in "Java" `{ com.google.android.gms.common.api.GoogleApiClient$ConnectionCallbacks `}
	super JavaObject

	fun on_connected(arg0: NativeBundle) in "Java" `{
		recv.onConnected(arg0);
	`}

	fun on_connection_suspended(arg0: Int) in "Java" `{
		recv.onConnectionSuspended((int)arg0);
	`}
end

extern class NativeGoogleApiClientOnConnectionFailedListener in "Java" `{ com.google.android.gms.common.api.GoogleApiClient$OnConnectionFailedListener `}
	super JavaObject

#	fun on_connection_failed(arg0: NativeConnectionResult) in "Java" `{
#		recv.onConnectionFailed(arg0);
#	`}
end
