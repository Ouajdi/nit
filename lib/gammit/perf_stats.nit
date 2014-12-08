# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#

import realtime

# Statistics on wall clock execution time of a category of events by `name`
#
# AccumulatedTime
# TimeStatCollection
# Times
# TimeAnalysis
class TimeStat
	# Name of the category
	var name: String

	# Shortest execution time of registered events
	var min: Float = -1.0

	# Longest execution time of registered events
	var max: Float = 0.0

	# Average execution time of registered events
	var avg: Float = 0.0

	# Number of registered events
	var count: Int = 0

	# Register a new event execution time with a `Timespec`
	fun add(lapse: Timespec) do add_float lapse.to_f

	# Register a new event execution time with a `Float`
	fun add_float(time: Float)
	do
		if time.to_f < min.to_f or min == -1.0 then min = time
		if time.to_f > max.to_f then max = time

		avg = (avg * count.to_f + time) / (count+1).to_f
		count += 1
	end

	redef fun to_s do return "min {min}, max {max}, avg {avg}, count {count}"
end

# Statistics collection on many events
class TimeStatMap
	super HashMap[String, TimeStat]

	redef fun provide_default_value(key)
	do
		var ts = new TimeStat(key)
		self[key] = ts
		return ts
	end

	redef fun to_s
	do
		var lines = new Array[String]
		for k, v in self do lines.add "* {k}: {v}"
		return lines.join("\n")
	end
end

redef class Sys
	# perf_analysis
	# perf_stats
	# event_perf
	# event_times
	# time_stats
	var time_stats = new TimeStatMap
end
