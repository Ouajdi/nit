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

import portaudio

class Receiver
	super PaCallbackReceiver

	redef fun callback(input_buffer, output_buffer,
		frames_per_buffer, out_time)
	do
		
		return false
	end
end

var n_sec = 5
var sample_rate = 44100.0
var frames_per_buffer = 64

var pa = new Portaudio
pa.assert_success

var output_device = pa.default_output_device
assert not output_device.no_device

var receiver = new Receiver

var stream = pa.open_stream(null, new StreamConfig(output_device, 2, new SampleFormat.float32), 
	33100.0, 64, 1, new StreamFlags.clip_off, receiver)
pa.assert_success

stream.start

pa.sleep(n_sec * 1000)

stream.stop

pa.destroy
