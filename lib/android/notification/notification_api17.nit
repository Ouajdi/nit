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

module notification_api17 is min_api_version 17

intrude import notification_api16
intrude import notification
import standard

in "Java" `{
	//import java.lang.*;
`}

redef extern class NativeNotificationBuilder
	fun show_when=(value: Bool) in "Java" `{ recv.setShowWhen(value); `}
end
