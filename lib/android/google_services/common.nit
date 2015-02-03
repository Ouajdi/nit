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
module gms_common_api

import mnit_android

extern class NativeResult in "Java" `{ com.google.android.gms.common.api.PendingResult.R.com.google.android.gms.common.api.Result `}
	super JavaObject

#	fun await0: NativeR  in "Java" `{
#		recv.await();
#	`}
#	fun await1(arg0: Int, arg1: NativeTimeUnit): NativeR  in "Java" `{
#		recv.await(arg0, arg1);
#	`}
	fun cancel in "Java" `{
		recv.cancel();
	`}
	fun is_canceled: Bool  in "Java" `{
		return recv.isCanceled();
	`}
#	fun result_callback0=(arg0: NativeResultCallbackOfR[NativeR]) in "Java" `{
#		recv.setResultCallback(arg0);
#	`}
#	fun result_callback1=(arg0: NativeResultCallbackOfR[NativeR]) in "Java" `{
#		recv.setResultCallback(arg0);
#	`}
#	fun a(arg0: NativePendingResulta) in "Java" `{
#		recv.a(arg0);
#	`}

end
