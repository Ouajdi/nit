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
module message_api

import mnit_android
import android::leaderboards

extern class NativeMessageApi in "Java" `{ com.google.android.gms.wearable.MessageApi `}
	super JavaObject

#	fun send_message(arg0: GoogleApiClient, arg1: JavaString, arg2: JavaString, arg3: NativeByteArray): NativePendingResultOfMessageApiSendMessageResult[NativeMessageApiSendMessageResult]  in "Java" `{
#		recv.sendMessage(arg0, arg1, arg2, arg3);
#	`}
#	fun add_listener(arg0: GoogleApiClient, arg1: NativeMessageApiMessageListener): NativePendingResultOfStatus[NativeStatus]  in "Java" `{
#		recv.addListener(arg0, arg1);
#	`}
#	fun remove_listener(arg0: GoogleApiClient, arg1: NativeMessageApiMessageListener): NativePendingResultOfStatus[NativeStatus]  in "Java" `{
#		recv.removeListener(arg0, arg1);
#	`}

end
